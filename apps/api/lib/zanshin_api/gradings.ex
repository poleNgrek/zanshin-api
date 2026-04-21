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

  alias ZanshinApi.Repo

  def create_session(attrs) do
    %GradingSession{}
    |> GradingSession.changeset(attrs)
    |> Repo.insert()
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
  end

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
    attrs = Map.put(attrs, "grading_result_id", result_id)

    %GradingVote{}
    |> GradingVote.changeset(attrs)
    |> Repo.insert()
  end

  def list_votes(result_id) do
    GradingVote
    |> where([v], v.grading_result_id == ^result_id)
    |> order_by([v], asc: v.inserted_at)
    |> Repo.all()
  end

  def create_note(result_id, attrs) do
    attrs = Map.put(attrs, "grading_result_id", result_id)

    %GradingNote{}
    |> GradingNote.changeset(attrs)
    |> Repo.insert()
  end

  def list_notes(result_id) do
    GradingNote
    |> where([n], n.grading_result_id == ^result_id)
    |> order_by([n], asc: n.inserted_at)
    |> Repo.all()
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
end
