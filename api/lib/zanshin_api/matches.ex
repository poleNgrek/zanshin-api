defmodule ZanshinApi.Matches do
  @moduledoc """
  Match context for lifecycle operations and audited transitions.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias ZanshinApi.Competitions.Division
  alias ZanshinApi.Competitions
  alias ZanshinApi.Events
  alias ZanshinApi.Matches.{Match, MatchEvent, ScoreEvent, StateMachine, Timer, TimerEvent}
  alias ZanshinApi.Repo

  @type actor_role :: :admin | :timekeeper | :shinpan
  @type score_type :: :ippon | :hansoku
  @type side :: :aka | :shiro
  @type target :: :men | :kote | :do | :tsuki
  @type timer_command :: :start | :pause | :resume | :overtime

  @spec create_match(map()) :: {:ok, Match.t()} | {:error, Ecto.Changeset.t()}
  def create_match(attrs) do
    with :ok <- ensure_division_belongs_to_tournament(attrs) do
      %Match{}
      |> Match.create_changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, match} ->
          broadcast_match_event("match_created", match.id, match.tournament_id, %{
            match_id: match.id,
            tournament_id: match.tournament_id,
            division_id: match.division_id,
            state: Atom.to_string(match.state)
          })

          {:ok, match}

        error ->
          error
      end
    end
  end

  @spec get_match(Ecto.UUID.t()) :: Match.t() | nil
  def get_match(id), do: Repo.get(Match, id)

  @spec list_matches() :: [Match.t()]
  def list_matches do
    Match
    |> order_by([m], desc: m.inserted_at)
    |> Repo.all()
  end

  @spec transition_match(Ecto.UUID.t(), StateMachine.transition_event(), actor_role()) ::
          {:ok, Match.t()} | {:error, atom() | Ecto.Changeset.t() | tuple()}
  def transition_match(match_id, event, actor_role) do
    with {:ok, role} <- normalize_actor_role(actor_role),
         {:ok, match} <- fetch_match(match_id),
         :ok <- authorize_transition(event, role),
         {:ok, new_state} <- StateMachine.transition(match.state, event) do
      Multi.new()
      |> Multi.update(:match, Match.transition_changeset(match, %{state: new_state}))
      |> Multi.insert(:match_event, fn %{match: updated_match} ->
        MatchEvent.changeset(%MatchEvent{}, %{
          match_id: updated_match.id,
          event: event,
          from_state: match.state,
          to_state: new_state,
          actor_role: role
        })
      end)
      |> Multi.insert(:domain_event, fn %{match_event: match_event} ->
        Events.new_domain_event_changeset(%{
          event_type: "match.transitioned",
          event_version: 1,
          aggregate_type: "match",
          aggregate_id: match.id,
          occurred_at: DateTime.utc_now(),
          actor_role: Atom.to_string(role),
          source: "matches.transition_match",
          causation_id: match_event.id,
          payload: %{
            event: Atom.to_string(event),
            from_state: Atom.to_string(match.state),
            to_state: Atom.to_string(new_state),
            match_id: match.id,
            tournament_id: match.tournament_id,
            division_id: match.division_id
          }
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{match: updated_match}} ->
          broadcast_match_event(
            "match_transitioned",
            updated_match.id,
            updated_match.tournament_id,
            %{
              match_id: updated_match.id,
              tournament_id: updated_match.tournament_id,
              division_id: updated_match.division_id,
              event: Atom.to_string(event),
              from_state: Atom.to_string(match.state),
              to_state: Atom.to_string(updated_match.state),
              actor_role: Atom.to_string(role)
            }
          )

          {:ok, updated_match}

        {:error, _step, reason, _changes} ->
          {:error, reason}
      end
    end
  end

  defp fetch_match(id) do
    case Repo.get(Match, id) do
      nil -> {:error, :match_not_found}
      match -> {:ok, match}
    end
  end

  defp ensure_division_belongs_to_tournament(attrs) do
    division_id = Map.get(attrs, "division_id") || Map.get(attrs, :division_id)
    tournament_id = Map.get(attrs, "tournament_id") || Map.get(attrs, :tournament_id)

    cond do
      is_nil(division_id) or is_nil(tournament_id) ->
        :ok

      true ->
        case Repo.get(Division, division_id) do
          nil ->
            :ok

          %Division{tournament_id: ^tournament_id} ->
            :ok

          _ ->
            {:error, :division_not_in_tournament}
        end
    end
  end

  # Role policy for phase 2:
  # - admin/timekeeper can drive lifecycle transitions
  # - shinpan can only pause/resume ongoing matches
  defp authorize_transition(event, role) do
    case {role, event} do
      {:admin, _} -> :ok
      {:timekeeper, _} -> :ok
      {:shinpan, e} when e in [:pause, :resume] -> :ok
      _ -> {:error, :forbidden_transition_for_role}
    end
  end

  defp normalize_actor_role(role) when role in [:admin, :timekeeper, :shinpan], do: {:ok, role}
  defp normalize_actor_role(_), do: {:error, :invalid_actor_role}

  @spec record_score_event(Ecto.UUID.t(), score_type(), side(), target() | nil, actor_role()) ::
          {:ok, ScoreEvent.t()} | {:error, atom() | Ecto.Changeset.t()}
  def record_score_event(match_id, score_type, side, target, actor_role) do
    with {:ok, role} <- normalize_actor_role(actor_role),
         :ok <- authorize_score_role(role),
         {:ok, normalized_score_type} <- normalize_score_type(score_type),
         {:ok, normalized_side} <- normalize_side(side),
         {:ok, normalized_target} <- normalize_target(target),
         {:ok, match} <- fetch_match(match_id),
         :ok <- require_ongoing_match(match),
         :ok <- validate_target_rules(match, normalized_score_type, normalized_target) do
      Multi.new()
      |> Multi.insert(:score_event, fn _ ->
        ScoreEvent.changeset(%ScoreEvent{}, %{
          match_id: match.id,
          score_type: normalized_score_type,
          side: normalized_side,
          target: normalized_target,
          actor_role: role
        })
      end)
      |> Multi.insert(:domain_event, fn %{score_event: score_event} ->
        Events.new_domain_event_changeset(%{
          event_type: "match.score_recorded",
          event_version: 1,
          aggregate_type: "match",
          aggregate_id: match.id,
          occurred_at: DateTime.utc_now(),
          actor_role: Atom.to_string(role),
          source: "matches.record_score_event",
          causation_id: score_event.id,
          payload: %{
            match_id: match.id,
            tournament_id: match.tournament_id,
            division_id: match.division_id,
            score_event_id: score_event.id,
            score_type: Atom.to_string(normalized_score_type),
            side: Atom.to_string(normalized_side),
            target: if(normalized_target, do: Atom.to_string(normalized_target), else: nil)
          }
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{score_event: score_event}} ->
          broadcast_match_event(
            "score_recorded",
            match.id,
            match.tournament_id,
            %{
              match_id: match.id,
              tournament_id: match.tournament_id,
              division_id: match.division_id,
              score_event_id: score_event.id,
              score_type: Atom.to_string(score_event.score_type),
              side: Atom.to_string(score_event.side),
              target: if(score_event.target, do: Atom.to_string(score_event.target), else: nil),
              actor_role: Atom.to_string(role)
            }
          )

          {:ok, score_event}

        {:error, _step, reason, _changes} ->
          {:error, reason}
      end
    end
  end

  @spec list_score_events(Ecto.UUID.t()) :: [ScoreEvent.t()]
  def list_score_events(match_id) do
    ScoreEvent
    |> where([s], s.match_id == ^match_id)
    |> order_by([s], asc: s.inserted_at)
    |> Repo.all()
  end

  @spec start_timer(Ecto.UUID.t(), actor_role(), DateTime.t()) ::
          {:ok, Timer.t()} | {:error, atom() | Ecto.Changeset.t()}
  def start_timer(match_id, actor_role, occurred_at \\ DateTime.utc_now()) do
    apply_timer_command(match_id, :start, actor_role, occurred_at)
  end

  @spec pause_timer(Ecto.UUID.t(), actor_role(), DateTime.t()) ::
          {:ok, Timer.t()} | {:error, atom() | Ecto.Changeset.t()}
  def pause_timer(match_id, actor_role, occurred_at \\ DateTime.utc_now()) do
    apply_timer_command(match_id, :pause, actor_role, occurred_at)
  end

  @spec resume_timer(Ecto.UUID.t(), actor_role(), DateTime.t()) ::
          {:ok, Timer.t()} | {:error, atom() | Ecto.Changeset.t()}
  def resume_timer(match_id, actor_role, occurred_at \\ DateTime.utc_now()) do
    apply_timer_command(match_id, :resume, actor_role, occurred_at)
  end

  @spec enter_overtime(Ecto.UUID.t(), actor_role(), DateTime.t()) ::
          {:ok, Timer.t()} | {:error, atom() | Ecto.Changeset.t()}
  def enter_overtime(match_id, actor_role, occurred_at \\ DateTime.utc_now()) do
    apply_timer_command(match_id, :overtime, actor_role, occurred_at)
  end

  @spec get_timer(Ecto.UUID.t()) :: Timer.t() | nil
  def get_timer(match_id), do: Repo.get_by(Timer, match_id: match_id)

  @spec list_timer_events(Ecto.UUID.t()) :: [TimerEvent.t()]
  def list_timer_events(match_id) do
    case Repo.get_by(Timer, match_id: match_id) do
      nil ->
        []

      timer ->
        TimerEvent
        |> where([event], event.timer_id == ^timer.id)
        |> order_by([event], asc: event.inserted_at)
        |> Repo.all()
    end
  end

  @spec reconstruct_timer(Ecto.UUID.t()) ::
          {:ok, %{status: atom(), elapsed_ms: integer(), run_started_at: DateTime.t() | nil}}
          | {:error, :timer_not_found}
  def reconstruct_timer(match_id) do
    case Repo.get_by(Timer, match_id: match_id) do
      nil ->
        {:error, :timer_not_found}

      timer ->
        events =
          TimerEvent
          |> where([event], event.timer_id == ^timer.id)
          |> order_by([event], asc: event.inserted_at)
          |> Repo.all()

        reconstructed =
          Enum.reduce(events, %{status: :idle, elapsed_ms: 0, run_started_at: nil}, fn event,
                                                                                       acc ->
            %{
              status: event.to_status,
              elapsed_ms: event.elapsed_after_ms,
              run_started_at:
                case event.to_status do
                  status when status in [:running, :overtime] -> event.occurred_at
                  _ -> nil
                end,
              previous: acc
            }
          end)

        {:ok, Map.take(reconstructed, [:status, :elapsed_ms, :run_started_at])}
    end
  end

  defp authorize_score_role(role) when role in [:admin, :shinpan], do: :ok
  defp authorize_score_role(_), do: {:error, :forbidden_score_for_role}

  defp authorize_timer_command(command, role) do
    case {role, command} do
      {:admin, _} -> :ok
      {:timekeeper, _} -> :ok
      {:shinpan, command} when command in [:pause, :resume] -> :ok
      _ -> {:error, :forbidden_timer_command_for_role}
    end
  end

  defp apply_timer_command(match_id, command, actor_role, occurred_at) do
    with {:ok, role} <- normalize_actor_role(actor_role),
         :ok <- authorize_timer_command(command, role),
         {:ok, _match} <- fetch_match(match_id),
         {:ok, timer} <- fetch_or_create_timer(match_id),
         {:ok, transition} <- timer_transition(timer, command, occurred_at) do
      Multi.new()
      |> Multi.update(
        :timer,
        Timer.changeset(timer, %{
          status: transition.to_status,
          elapsed_ms: transition.elapsed_after_ms,
          run_started_at: transition.run_started_at
        })
      )
      |> Multi.insert(:timer_event, fn %{timer: updated_timer} ->
        TimerEvent.changeset(%TimerEvent{}, %{
          timer_id: updated_timer.id,
          command: command,
          from_status: timer.status,
          to_status: transition.to_status,
          elapsed_before_ms: timer.elapsed_ms,
          elapsed_after_ms: transition.elapsed_after_ms,
          occurred_at: occurred_at,
          actor_role: role,
          metadata: transition.metadata
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{timer: updated_timer}} ->
          case get_match(match_id) do
            %Match{} = match ->
              broadcast_match_event(
                "timer_updated",
                match.id,
                match.tournament_id,
                %{
                  match_id: match.id,
                  tournament_id: match.tournament_id,
                  division_id: match.division_id,
                  command: Atom.to_string(command),
                  from_status: Atom.to_string(timer.status),
                  to_status: Atom.to_string(updated_timer.status),
                  elapsed_ms: updated_timer.elapsed_ms,
                  actor_role: Atom.to_string(role)
                }
              )

            _ ->
              :ok
          end

          {:ok, updated_timer}

        {:error, _step, reason, _changes} ->
          {:error, reason}
      end
    end
  end

  defp fetch_or_create_timer(match_id) do
    case Repo.get_by(Timer, match_id: match_id) do
      nil ->
        %Timer{}
        |> Timer.changeset(%{match_id: match_id, status: :idle, elapsed_ms: 0})
        |> Repo.insert()

      timer ->
        {:ok, timer}
    end
  end

  defp timer_transition(%Timer{status: :idle}, :start, occurred_at) do
    {:ok, %{to_status: :running, elapsed_after_ms: 0, run_started_at: occurred_at, metadata: %{}}}
  end

  defp timer_transition(%Timer{status: :running} = timer, :pause, occurred_at) do
    with {:ok, elapsed_after_ms} <- elapsed_after_pause(timer, occurred_at) do
      {:ok,
       %{
         to_status: :paused,
         elapsed_after_ms: elapsed_after_ms,
         run_started_at: nil,
         metadata: %{}
       }}
    end
  end

  defp timer_transition(%Timer{status: :overtime} = timer, :pause, occurred_at) do
    with {:ok, elapsed_after_ms} <- elapsed_after_pause(timer, occurred_at) do
      {:ok,
       %{
         to_status: :paused,
         elapsed_after_ms: elapsed_after_ms,
         run_started_at: nil,
         metadata: %{overtime_paused: true}
       }}
    end
  end

  defp timer_transition(%Timer{status: :paused} = timer, :resume, occurred_at) do
    {:ok,
     %{
       to_status: :running,
       elapsed_after_ms: timer.elapsed_ms,
       run_started_at: occurred_at,
       metadata: %{}
     }}
  end

  defp timer_transition(%Timer{status: :running} = timer, :overtime, occurred_at) do
    {:ok,
     %{
       to_status: :overtime,
       elapsed_after_ms: timer.elapsed_ms,
       run_started_at: timer.run_started_at || occurred_at,
       metadata: %{overtime_started: true}
     }}
  end

  defp timer_transition(%Timer{status: :paused} = timer, :overtime, occurred_at) do
    {:ok,
     %{
       to_status: :overtime,
       elapsed_after_ms: timer.elapsed_ms,
       run_started_at: occurred_at,
       metadata: %{overtime_started: true}
     }}
  end

  defp timer_transition(_timer, _command, _occurred_at), do: {:error, :invalid_timer_transition}

  defp elapsed_after_pause(%Timer{run_started_at: nil}, _occurred_at),
    do: {:error, :timer_not_running}

  defp elapsed_after_pause(
         %Timer{elapsed_ms: elapsed_ms, run_started_at: started_at},
         occurred_at
       ) do
    elapsed_delta_ms = DateTime.diff(occurred_at, started_at, :millisecond)

    if elapsed_delta_ms < 0 do
      {:error, :invalid_timer_clock}
    else
      {:ok, elapsed_ms + elapsed_delta_ms}
    end
  end

  defp broadcast_match_event(event_name, match_id, tournament_id, payload) do
    payload = Map.put(payload, :occurred_at, DateTime.utc_now() |> DateTime.truncate(:second))

    ZanshinApiWeb.Endpoint.broadcast("matches:all", event_name, payload)
    ZanshinApiWeb.Endpoint.broadcast("matches:tournament:#{tournament_id}", event_name, payload)
    ZanshinApiWeb.Endpoint.broadcast("matches:match:#{match_id}", event_name, payload)
  end

  defp require_ongoing_match(%Match{state: :ongoing}), do: :ok
  defp require_ongoing_match(_), do: {:error, :match_not_ongoing}

  defp normalize_score_type(value) when value in [:ippon, :hansoku], do: {:ok, value}
  defp normalize_score_type(_), do: {:error, :invalid_score_type}

  defp normalize_side(value) when value in [:aka, :shiro], do: {:ok, value}
  defp normalize_side(_), do: {:error, :invalid_side}

  defp normalize_target(nil), do: {:ok, nil}
  defp normalize_target(value) when value in [:men, :kote, :do, :tsuki], do: {:ok, value}
  defp normalize_target(_), do: {:error, :invalid_target}

  defp validate_target_rules(_match, :hansoku, _target), do: :ok

  defp validate_target_rules(match, :ippon, target) do
    with :ok <- require_target_for_ippon(target),
         :ok <- ensure_tsuki_allowed(match, target) do
      :ok
    end
  end

  defp require_target_for_ippon(nil), do: {:error, :invalid_target}
  defp require_target_for_ippon(_), do: :ok

  defp ensure_tsuki_allowed(_match, target) when target != :tsuki, do: :ok

  defp ensure_tsuki_allowed(%Match{division_id: division_id}, :tsuki) do
    case Competitions.get_division_rules(division_id) do
      nil -> :ok
      %{allow_tsuki: true} -> :ok
      %{allow_tsuki: false} -> {:error, :tsuki_not_allowed}
    end
  end
end
