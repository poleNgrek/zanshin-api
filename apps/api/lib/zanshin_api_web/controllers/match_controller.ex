defmodule ZanshinApiWeb.MatchController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Matches
  alias ZanshinApi.Matches.Match

  def index(conn, _params) do
    payload =
      Matches.list_matches()
      |> Enum.map(&serialize_match/1)

    json(conn, %{data: payload})
  end

  def create(conn, params) do
    with :ok <- authorize_create(conn),
         {:ok, match} <- Matches.create_match(params) do
      conn
      |> put_status(:created)
      |> json(%{data: serialize_match(match)})
    else
      {:error, :forbidden} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "forbidden"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_match_payload", details: changeset_errors(changeset)})
    end
  end

  def show(conn, %{"id" => id}) do
    case Matches.get_match(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "match_not_found"})

      match ->
        json(conn, %{data: serialize_match(match)})
    end
  end

  defp serialize_match(%Match{} = match) do
    %{
      id: match.id,
      tournament_id: match.tournament_id,
      division_id: match.division_id,
      aka_competitor_id: match.aka_competitor_id,
      shiro_competitor_id: match.shiro_competitor_id,
      state: to_string(match.state),
      inserted_at: match.inserted_at
    }
  end

  defp authorize_create(conn) do
    case conn.assigns[:current_role] do
      role when role in [:admin, :timekeeper] -> :ok
      _ -> {:error, :forbidden}
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
