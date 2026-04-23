defmodule ZanshinApi.Matches do
  @moduledoc """
  Match context for lifecycle operations and audited transitions.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias ZanshinApi.Competitions.Division
  alias ZanshinApi.Competitions
  alias ZanshinApi.Events
  alias ZanshinApi.Matches.{Match, MatchEvent, ScoreEvent, StateMachine}
  alias ZanshinApi.Repo

  @type actor_role :: :admin | :timekeeper | :shinpan
  @type score_type :: :ippon | :hansoku
  @type side :: :aka | :shiro
  @type target :: :men | :kote | :do | :tsuki

  @spec create_match(map()) :: {:ok, Match.t()} | {:error, Ecto.Changeset.t()}
  def create_match(attrs) do
    with :ok <- ensure_division_belongs_to_tournament(attrs) do
      %Match{}
      |> Match.create_changeset(attrs)
      |> Repo.insert()
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
            match_id: match.id
          }
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{match: updated_match}} -> {:ok, updated_match}
        {:error, _step, reason, _changes} -> {:error, reason}
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
            score_event_id: score_event.id,
            score_type: Atom.to_string(normalized_score_type),
            side: Atom.to_string(normalized_side),
            target: if(normalized_target, do: Atom.to_string(normalized_target), else: nil)
          }
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{score_event: score_event}} -> {:ok, score_event}
        {:error, _step, reason, _changes} -> {:error, reason}
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

  defp authorize_score_role(role) when role in [:admin, :shinpan], do: :ok
  defp authorize_score_role(_), do: {:error, :forbidden_score_for_role}

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
