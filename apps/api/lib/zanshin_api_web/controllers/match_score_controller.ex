defmodule ZanshinApiWeb.MatchScoreController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Matches
  alias ZanshinApi.Matches.ScoreEvent

  def create(conn, %{"id" => match_id, "score_type" => score_type, "side" => side}) do
    with {:ok, role} <- current_actor_role(conn),
         {:ok, score_event} <-
           Matches.record_score_event(
             match_id,
             parse_score_type(score_type),
             parse_side(side),
             role
           ) do
      conn
      |> put_status(:created)
      |> json(%{data: serialize(score_event)})
    else
      {:error, :unauthorized} ->
        conn |> put_status(:unauthorized) |> json(%{error: "unauthorized"})

      {:error, :invalid_score_type} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "invalid_score_type"})

      {:error, :invalid_side} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "invalid_side"})

      {:error, :match_not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "match_not_found"})

      {:error, :match_not_ongoing} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "match_not_ongoing"})

      {:error, :forbidden_score_for_role} ->
        conn |> put_status(:forbidden) |> json(%{error: "forbidden_score_for_role"})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_score_payload", details: changeset_errors(changeset)})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "match_id_score_type_and_side_are_required"})
  end

  def index(conn, %{"id" => match_id}) do
    data = Matches.list_score_events(match_id) |> Enum.map(&serialize/1)
    json(conn, %{data: data})
  end

  defp current_actor_role(conn) do
    case conn.assigns[:current_role] do
      nil -> {:error, :unauthorized}
      role -> {:ok, role}
    end
  end

  defp parse_score_type("ippon"), do: :ippon
  defp parse_score_type("hansoku"), do: :hansoku
  defp parse_score_type(_), do: :invalid

  defp parse_side("aka"), do: :aka
  defp parse_side("shiro"), do: :shiro
  defp parse_side(_), do: :invalid

  defp serialize(%ScoreEvent{} = event) do
    %{
      id: event.id,
      match_id: event.match_id,
      score_type: to_string(event.score_type),
      side: to_string(event.side),
      actor_role: to_string(event.actor_role),
      inserted_at: event.inserted_at
    }
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
