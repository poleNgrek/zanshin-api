defmodule ZanshinApi.Matches.StateMachine do
  @moduledoc """
  Encodes allowed state transitions for tournament matches.

  This module captures the strict lifecycle defined in the PRD:
  scheduled -> ready -> ongoing -> paused -> ongoing -> completed -> verified
  """

  @type match_state :: :scheduled | :ready | :ongoing | :paused | :completed | :verified
  @type transition_event ::
          :prepare
          | :start
          | :pause
          | :resume
          | :complete
          | :verify
          | :cancel

  @transitions %{
    scheduled: %{prepare: :ready, cancel: :completed},
    ready: %{start: :ongoing, cancel: :completed},
    ongoing: %{pause: :paused, complete: :completed, cancel: :completed},
    paused: %{resume: :ongoing, cancel: :completed},
    completed: %{verify: :verified},
    verified: %{}
  }

  @match_states Map.keys(@transitions)
  @transition_events [:prepare, :start, :pause, :resume, :complete, :verify, :cancel]

  @spec states() :: [match_state()]
  def states, do: @match_states

  @spec events() :: [transition_event()]
  def events, do: @transition_events

  @spec parse_state(String.t()) :: {:ok, match_state()} | {:error, :invalid_state}
  def parse_state(value) when is_binary(value) do
    with {:ok, atom} <- string_to_existing_transition_atom(value),
         true <- atom in @match_states do
      {:ok, atom}
    else
      _ -> {:error, :invalid_state}
    end
  end

  @spec parse_event(String.t()) :: {:ok, transition_event()} | {:error, :invalid_event}
  def parse_event(value) when is_binary(value) do
    with {:ok, atom} <- string_to_existing_transition_atom(value),
         true <- atom in @transition_events do
      {:ok, atom}
    else
      _ -> {:error, :invalid_event}
    end
  end

  @spec transition(match_state(), transition_event()) ::
          {:ok, match_state()}
          | {:error, {:invalid_transition, match_state(), transition_event()}}
  def transition(current_state, event) do
    case get_in(@transitions, [current_state, event]) do
      nil -> {:error, {:invalid_transition, current_state, event}}
      new_state -> {:ok, new_state}
    end
  end

  defp string_to_existing_transition_atom(value) do
    try do
      {:ok, String.to_existing_atom(value)}
    rescue
      ArgumentError -> {:error, :invalid}
    end
  end
end
