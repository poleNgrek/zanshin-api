defmodule ZanshinApiWeb.MatchStateController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Matches
  alias ZanshinApi.Matches.StateMachine

  def transition(conn, %{"id" => id, "event" => event}) do
    with {:ok, event_atom} <- StateMachine.parse_event(event),
         {:ok, role} <- parse_actor_role(conn),
         {:ok, match} <- Matches.transition_match(id, event_atom, role) do
      json(conn, %{data: %{id: match.id, new_state: to_string(match.state)}})
    else
      {:error, :invalid_event} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_event"})

      {:error, :invalid_actor_role} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "invalid_or_missing_actor_role"})

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
  end

  def transition(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "match_id_and_event_are_required"})
  end

  defp parse_actor_role(conn) do
    case get_req_header(conn, "x-actor-role") do
      [role] -> normalize_actor_role(role)
      _ -> {:error, :invalid_actor_role}
    end
  end

  defp normalize_actor_role("admin"), do: {:ok, :admin}
  defp normalize_actor_role("timekeeper"), do: {:ok, :timekeeper}
  defp normalize_actor_role("shinpan"), do: {:ok, :shinpan}
  defp normalize_actor_role(_), do: {:error, :invalid_actor_role}

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
