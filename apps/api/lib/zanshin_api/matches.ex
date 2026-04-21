defmodule ZanshinApi.Matches do
  @moduledoc """
  Match context for lifecycle operations and audited transitions.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias ZanshinApi.Matches.{Match, MatchEvent, StateMachine}
  alias ZanshinApi.Repo

  @type actor_role :: :admin | :timekeeper | :shinpan

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
end
