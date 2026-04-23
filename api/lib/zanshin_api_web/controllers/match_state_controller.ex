defmodule ZanshinApiWeb.MatchStateController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Matches
  alias ZanshinApi.Matches.StateMachine
  alias ZanshinApiWeb.Idempotency

  def transition(conn, %{"id" => id, "event" => event} = params) do
    Idempotency.run(conn, params, fn ->
      with {:ok, event_atom} <- StateMachine.parse_event(event),
           {:ok, role} <- current_actor_role(conn),
           {:ok, match} <- Matches.transition_match(id, event_atom, role) do
        json(conn, %{data: %{id: match.id, new_state: to_string(match.state)}})
      else
        {:error, :invalid_event} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: "invalid_event"})

        {:error, :missing_actor_role} ->
          conn
          |> put_status(:unauthorized)
          |> json(%{error: "unauthorized"})

        {:error, :forbidden_transition_for_role} ->
          conn
          |> put_status(:forbidden)
          |> json(%{error: "forbidden_transition_for_role"})

        {:error, :match_not_found} ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "match_not_found"})

        {:error, {:invalid_transition, _state, _event_atom}} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: "invalid_transition"})

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: "transition_persistence_failed", details: changeset_errors(changeset)})
      end
    end)
  end

  def transition(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "match_id_and_event_are_required"})
  end

  defp current_actor_role(conn) do
    case conn.assigns[:current_role] do
      nil -> {:error, :missing_actor_role}
      role -> {:ok, role}
    end
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
