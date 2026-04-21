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

  @spec transition(match_state(), transition_event()) ::
          {:ok, match_state()} | {:error, {:invalid_transition, match_state(), transition_event()}}
  def transition(current_state, event) do
    case get_in(@transitions, [current_state, event]) do
      nil -> {:error, {:invalid_transition, current_state, event}}
      new_state -> {:ok, new_state}
    end
  end
end
