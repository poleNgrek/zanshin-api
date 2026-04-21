defmodule ZanshinApiWeb.CompetitorController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Competitions
  alias ZanshinApi.Competitions.Competitor

  def index(conn, _params) do
    data = Competitions.list_competitors() |> Enum.map(&serialize/1)
    json(conn, %{data: data})
  end

  def create(conn, params) do
    with :ok <- authorize_write(conn),
         {:ok, competitor} <- Competitions.create_competitor(params) do
      conn
      |> put_status(:created)
      |> json(%{data: serialize(competitor)})
    else
      {:error, :forbidden} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "forbidden"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_competitor_payload", details: changeset_errors(changeset)})
    end
  end

  defp serialize(%Competitor{} = competitor) do
    %{
      id: competitor.id,
      display_name: competitor.display_name,
      federation_id: competitor.federation_id
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
