defmodule ZanshinApi.Gradings do
  @moduledoc "Grading context for sessions, results, examiners, votes, and notes."

  import Ecto.Query, warn: false

  alias ZanshinApi.Grading.{
    GradingExaminer,
    GradingNote,
    GradingPanelAssignment,
    GradingResult,
    GradingSession,
    GradingVote
  }

  alias ZanshinApi.Realtime.AdminBroadcaster
  alias ZanshinApi.Repo

  def create_session(attrs) do
    %GradingSession{}
    |> GradingSession.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, session} ->
        AdminBroadcaster.broadcast("admin_grading_session_created", %{
          tournament_id: session.tournament_id,
          grading_session_id: session.id,
          session_name: session.name
        })

        {:ok, session}

      error ->
        error
    end
  end

  def list_sessions_by_tournament(tournament_id) do
    GradingSession
    |> where([s], s.tournament_id == ^tournament_id)
    |> order_by([s], desc: s.held_on, desc: s.inserted_at)
    |> Repo.all()
  end

  def create_result(session_id, attrs) do
    attrs = attrs |> Map.put("grading_session_id", session_id) |> with_result_defaults(session_id)

    %GradingResult{}
    |> GradingResult.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, result} ->
        with {:ok, session} <- fetch_session(result.grading_session_id) do
          AdminBroadcaster.broadcast("admin_grading_result_created", %{
            tournament_id: session.tournament_id,
            grading_session_id: session.id,
            grading_result_id: result.id
          })
        end

        {:ok, result}

      error ->
        error
    end
  end

  def get_result(result_id), do: Repo.get(GradingResult, result_id)

  def list_results_by_session(session_id) do
    GradingResult
    |> where([r], r.grading_session_id == ^session_id)
    |> order_by([r], asc: r.inserted_at)
    |> Repo.all()
  end

  def create_examiner(attrs) do
    %GradingExaminer{}
    |> GradingExaminer.changeset(attrs)
    |> Repo.insert()
  end

  def list_examiners do
    GradingExaminer
    |> order_by([e], asc: e.display_name)
    |> Repo.all()
  end

  def assign_examiner_to_session(session_id, attrs) do
    attrs = Map.put(attrs, "grading_session_id", session_id)

    %GradingPanelAssignment{}
    |> GradingPanelAssignment.changeset(attrs)
    |> Repo.insert()
  end

  def list_panel_assignments(session_id) do
    GradingPanelAssignment
    |> where([a], a.grading_session_id == ^session_id)
    |> order_by([a], asc: a.inserted_at)
    |> Repo.all()
  end

  def create_vote(result_id, attrs) do
    with {:ok, result} <- fetch_result(result_id),
         :ok <- ensure_unlocked(result),
         :ok <- ensure_examiner_assigned_to_result_session(result, attrs) do
      attrs = Map.put(attrs, "grading_result_id", result_id)

      %GradingVote{}
      |> GradingVote.changeset(attrs)
      |> Repo.insert()
    end
  end

  def list_votes(result_id) do
    GradingVote
    |> where([v], v.grading_result_id == ^result_id)
    |> order_by([v], asc: v.inserted_at)
    |> Repo.all()
  end

  def create_note(result_id, attrs) do
    with {:ok, result} <- fetch_result(result_id),
         :ok <- ensure_unlocked(result),
         :ok <- ensure_examiner_assigned_to_result_session(result, attrs) do
      attrs = Map.put(attrs, "grading_result_id", result_id)

      %GradingNote{}
      |> GradingNote.changeset(attrs)
      |> Repo.insert()
    end
  end

  def list_notes(result_id) do
    GradingNote
    |> where([n], n.grading_result_id == ^result_id)
    |> order_by([n], asc: n.inserted_at)
    |> Repo.all()
  end

  def compute_result_decision(result_id) do
    with {:ok, result} <- fetch_result(result_id),
         {:ok, session} <- fetch_session(result.grading_session_id) do
      panel_size = panel_size(session.id)
      required_pass_votes = required_pass_votes(session, panel_size)
      votes = list_votes(result.id)
      today = Date.utc_today()

      {jitsugi_outcome, jitsugi_stats, jitsugi_expired?} =
        evaluate_part(result, :jitsugi, votes, required_pass_votes, today, true)

      {kata_outcome, kata_stats, kata_expired?} =
        evaluate_part(result, :kata, votes, required_pass_votes, today, true)

      {written_outcome, written_stats, written_expired?} =
        evaluate_part(
          result,
          :written,
          votes,
          required_pass_votes,
          today,
          session.written_required
        )

      final_result =
        decide_final_result(
          jitsugi_outcome,
          kata_outcome,
          written_outcome,
          session.written_required,
          kata_expired? or written_expired?
        )

      carryover_until =
        next_carryover_until(
          result,
          session,
          final_result,
          jitsugi_outcome,
          kata_outcome,
          written_outcome,
          today
        )

      snapshot = %{
        computed_at: DateTime.utc_now(),
        panel_size: panel_size,
        required_pass_votes: required_pass_votes,
        parts: %{
          jitsugi: stats_map(jitsugi_outcome, jitsugi_stats, jitsugi_expired?),
          kata: stats_map(kata_outcome, kata_stats, kata_expired?),
          written: stats_map(written_outcome, written_stats, written_expired?)
        },
        final_result: Atom.to_string(final_result)
      }

      attrs = %{
        "jitsugi_result" => Atom.to_string(jitsugi_outcome),
        "kata_result" => Atom.to_string(kata_outcome),
        "written_result" => Atom.to_string(written_outcome),
        "final_result" => Atom.to_string(final_result),
        "carryover_until" => carryover_until,
        "computed_at" => DateTime.utc_now(),
        "decision_snapshot" => snapshot
      }

      result
      |> GradingResult.changeset(attrs)
      |> Repo.update()
      |> case do
        {:ok, updated} ->
          AdminBroadcaster.broadcast("admin_grading_result_computed", %{
            tournament_id: session.tournament_id,
            grading_session_id: session.id,
            grading_result_id: updated.id,
            final_result: Atom.to_string(updated.final_result)
          })

          {:ok, updated}

        error ->
          error
      end
    end
  end

  def finalize_result(result_id, actor_role) do
    with {:ok, result} <- fetch_result(result_id),
         :ok <- ensure_unlocked(result) do
      case result.decision_snapshot do
        nil ->
          with {:ok, computed} <- compute_result_decision(result_id) do
            lock_result(computed, actor_role)
          end

        _ ->
          lock_result(result, actor_role)
      end
    end
  end

  def result_decision_snapshot(result_id) do
    with {:ok, result} <- fetch_result(result_id),
         snapshot when is_map(snapshot) <- result.decision_snapshot do
      {:ok, snapshot}
    else
      {:error, _} = err -> err
      _ -> {:error, :decision_not_computed}
    end
  end

  defp with_result_defaults(attrs, session_id) do
    session = Repo.get(GradingSession, session_id)
    date = (session && session.held_on) || Date.utc_today()

    final_result =
      decide_final_result(
        part_result(attrs, "jitsugi_result", "not_attempted"),
        part_result(attrs, "kata_result", "not_attempted"),
        part_result(
          attrs,
          "written_result",
          if(session && session.written_required, do: "not_attempted", else: "waived")
        ),
        session && session.written_required
      )

    attrs
    |> Map.put_new("final_result", final_result)
    |> Map.put_new("jitsugi_result", part_result(attrs, "jitsugi_result", "not_attempted"))
    |> Map.put_new("kata_result", part_result(attrs, "kata_result", "not_attempted"))
    |> Map.put_new(
      "written_result",
      part_result(
        attrs,
        "written_result",
        if(session && session.written_required, do: "not_attempted", else: "waived")
      )
    )
    |> maybe_put_carryover(final_result, session, date)
  end

  defp decide_final_result("pass", "pass", written_result, written_required) do
    if written_required and written_result not in ["pass", "waived"], do: "pending", else: "pass"
  end

  defp decide_final_result("fail", _kata, _written, _required), do: "fail"
  defp decide_final_result(_jitsugi, "fail", _written, _required), do: "pending"

  defp decide_final_result(_jitsugi, _kata, "fail", true), do: "pending"
  defp decide_final_result(_jitsugi, _kata, _written, _required), do: "pending"

  defp maybe_put_carryover(attrs, "pending", session, date) do
    kata_months = (session && session.kata_carryover_months) || 12
    written_months = (session && session.written_carryover_months) || 12
    carryover_days = max(kata_months, written_months) * 30
    Map.put_new(attrs, "carryover_until", Date.add(date, carryover_days))
  end

  defp maybe_put_carryover(attrs, _result, _session, _date), do: attrs

  defp part_result(attrs, key, default) do
    Map.get(attrs, key) || Map.get(attrs, String.to_atom(key)) || default
  end

  defp fetch_result(result_id) do
    case Repo.get(GradingResult, result_id) do
      nil -> {:error, :grading_result_not_found}
      result -> {:ok, result}
    end
  end

  defp ensure_examiner_assigned_to_result_session(%GradingResult{} = result, attrs) do
    examiner_id = Map.get(attrs, "examiner_id") || Map.get(attrs, :examiner_id)

    if is_nil(examiner_id) do
      :ok
    else
      query =
        GradingPanelAssignment
        |> where(
          [assignment],
          assignment.grading_session_id == ^result.grading_session_id and
            assignment.examiner_id == ^examiner_id
        )
        |> select([assignment], assignment.id)
        |> limit(1)

      case Repo.one(query) do
        nil -> {:error, :examiner_not_assigned_to_session}
        _ -> :ok
      end
    end
  end

  defp fetch_session(session_id) do
    case Repo.get(GradingSession, session_id) do
      nil -> {:error, :grading_session_not_found}
      session -> {:ok, session}
    end
  end

  defp ensure_unlocked(%GradingResult{locked_at: nil}), do: :ok
  defp ensure_unlocked(_), do: {:error, :grading_result_locked}

  defp panel_size(session_id) do
    GradingPanelAssignment
    |> where([a], a.grading_session_id == ^session_id)
    |> Repo.aggregate(:count)
  end

  defp required_pass_votes(%GradingSession{required_pass_votes: value}, _panel_size)
       when is_integer(value),
       do: value

  defp required_pass_votes(_session, panel_size) when panel_size > 0, do: div(panel_size, 2) + 1
  defp required_pass_votes(_session, _panel_size), do: 1

  defp evaluate_part(result, part, votes, required_pass_votes, today, required?) do
    part_votes = Enum.filter(votes, &(&1.part == part))
    pass_votes = Enum.count(part_votes, &(&1.decision == :pass))
    fail_votes = Enum.count(part_votes, &(&1.decision == :fail))
    existing = Map.get(result, :"#{part}_result")
    carryover_expired? = existing == :carried_over and carryover_expired?(result, today)

    outcome =
      cond do
        part == :written and not required? ->
          :waived

        carryover_expired? ->
          :fail

        pass_votes + fail_votes > 0 and pass_votes >= required_pass_votes ->
          :pass

        pass_votes + fail_votes > 0 ->
          :fail

        existing in [:pass, :carried_over, :waived] ->
          existing

        true ->
          :not_attempted
      end

    stats = %{pass_votes: pass_votes, fail_votes: fail_votes}
    {outcome, stats, carryover_expired?}
  end

  defp decide_final_result(jitsugi, kata, written, written_required, carryover_expired?) do
    cond do
      jitsugi == :fail ->
        :fail

      carryover_expired? ->
        :fail

      jitsugi != :pass ->
        :pending

      kata in [:fail, :not_attempted] ->
        :pending

      written_required and written in [:fail, :not_attempted] ->
        :pending

      true ->
        :pass
    end
  end

  defp next_carryover_until(result, session, final_result, jitsugi, kata, written, today) do
    if final_result == :pending and jitsugi == :pass do
      months =
        []
        |> maybe_add_months(kata in [:fail, :not_attempted], session.kata_carryover_months || 12)
        |> maybe_add_months(
          session.written_required and written in [:fail, :not_attempted],
          session.written_carryover_months || 12
        )

      case months do
        [] ->
          result.carryover_until

        values ->
          candidate = Date.add(today, Enum.max(values) * 30)

          if result.carryover_until && Date.compare(result.carryover_until, candidate) == :gt,
            do: result.carryover_until,
            else: candidate
      end
    else
      nil
    end
  end

  defp maybe_add_months(list, true, months), do: [months | list]
  defp maybe_add_months(list, false, _months), do: list

  defp carryover_expired?(%GradingResult{carryover_until: nil}, _today), do: false

  defp carryover_expired?(%GradingResult{carryover_until: carryover_until}, today),
    do: Date.compare(carryover_until, today) == :lt

  defp stats_map(outcome, stats, expired?) do
    stats
    |> Map.put(:outcome, Atom.to_string(outcome))
    |> Map.put(:carryover_expired, expired?)
  end

  defp lock_result(result, actor_role) do
    snapshot =
      case result.decision_snapshot do
        %{} = map -> Map.put(map, :finalized_by_role, Atom.to_string(actor_role))
        _ -> %{finalized_by_role: Atom.to_string(actor_role)}
      end

    attrs = %{
      "locked_at" => DateTime.utc_now(),
      "finalized_at" => DateTime.utc_now(),
      "decision_snapshot" => snapshot
    }

    result
    |> GradingResult.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated} ->
        with {:ok, session} <- fetch_session(updated.grading_session_id) do
          AdminBroadcaster.broadcast("admin_grading_result_finalized", %{
            tournament_id: session.tournament_id,
            grading_session_id: session.id,
            grading_result_id: updated.id
          })
        end

        {:ok, updated}

      error ->
        error
    end
  end
end
