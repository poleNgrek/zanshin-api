defmodule ZanshinApiWeb.DivisionController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Competitions
  alias ZanshinApi.Competitions.Division

  def index(conn, params) do
    case Map.get(params, "tournament_id") do
      nil ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "tournament_id_required"})

      tournament_id ->
        data = Competitions.list_divisions_by_tournament(tournament_id) |> Enum.map(&serialize/1)
        json(conn, %{data: data})
    end
  end

  def create(conn, params) do
    with :ok <- authorize_write(conn),
         {:ok, division} <- Competitions.create_division(params) do
      conn
      |> put_status(:created)
      |> json(%{data: serialize(division)})
    else
      {:error, :forbidden} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "forbidden"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_division_payload", details: changeset_errors(changeset)})
    end
  end

  defp serialize(%Division{} = division) do
    %{
      id: division.id,
      tournament_id: division.tournament_id,
      name: division.name,
      format: to_string(division.format)
    }
  end

  defp authorize_write(conn) do
    if conn.assigns[:current_role] in [:admin, :timekeeper], do: :ok, else: {:error, :forbidden}
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
