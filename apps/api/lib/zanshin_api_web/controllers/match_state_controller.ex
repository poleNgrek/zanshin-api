defmodule ZanshinApiWeb.MatchStateController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Matches.StateMachine

  # This endpoint makes lifecycle rules explicit for early API consumers.
  # It gives us a stable contract while the rest of match persistence is built.
  def transition(conn, %{"current_state" => current_state, "event" => event}) do
    with {:ok, state} <- parse_state(current_state),
         {:ok, event_atom} <- parse_event(event),
         {:ok, new_state} <- StateMachine.transition(state, event_atom) do
      json(conn, %{current_state: Atom.to_string(state), new_state: Atom.to_string(new_state)})
    else
      {:error, :invalid_state} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_current_state"})

      {:error, :invalid_event} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_event"})

      {:error, {:invalid_transition, state, event_atom}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: "invalid_transition",
          current_state: Atom.to_string(state),
          event: Atom.to_string(event_atom)
        })
    end
  end

  def transition(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "current_state_and_event_are_required"})
  end

  defp parse_state(value) do
    case value do
      "scheduled" -> {:ok, :scheduled}
      "ready" -> {:ok, :ready}
      "ongoing" -> {:ok, :ongoing}
      "paused" -> {:ok, :paused}
      "completed" -> {:ok, :completed}
      "verified" -> {:ok, :verified}
      _ -> {:error, :invalid_state}
    end
  end

  defp parse_event(value) do
    case value do
      "prepare" -> {:ok, :prepare}
      "start" -> {:ok, :start}
      "pause" -> {:ok, :pause}
      "resume" -> {:ok, :resume}
      "complete" -> {:ok, :complete}
      "verify" -> {:ok, :verify}
      "cancel" -> {:ok, :cancel}
      _ -> {:error, :invalid_event}
    end
  end
end
