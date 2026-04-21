defmodule ZanshinApi.Matches do
  @moduledoc """
  Match context for lifecycle operations and audited transitions.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias ZanshinApi.Matches.{Match, MatchEvent, ScoreEvent, StateMachine}
  alias ZanshinApi.Repo

  @type actor_role :: :admin | :timekeeper | :shinpan
  @type score_type :: :ippon | :hansoku
  @type side :: :aka | :shiro

  @spec create_match(map()) :: {:ok, Match.t()} | {:error, Ecto.Changeset.t()}
  def create_match(attrs) do
    %Match{}
    |> Match.create_changeset(attrs)
    |> Repo.insert()
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

  @spec record_score_event(Ecto.UUID.t(), score_type(), side(), actor_role()) ::
          {:ok, ScoreEvent.t()} | {:error, atom() | Ecto.Changeset.t()}
  def record_score_event(match_id, score_type, side, actor_role) do
    with {:ok, role} <- normalize_actor_role(actor_role),
         :ok <- authorize_score_role(role),
         {:ok, normalized_score_type} <- normalize_score_type(score_type),
         {:ok, normalized_side} <- normalize_side(side),
         {:ok, match} <- fetch_match(match_id),
         :ok <- require_ongoing_match(match) do
      %ScoreEvent{}
      |> ScoreEvent.changeset(%{
        match_id: match.id,
        score_type: normalized_score_type,
        side: normalized_side,
        actor_role: role
      })
      |> Repo.insert()
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
end
