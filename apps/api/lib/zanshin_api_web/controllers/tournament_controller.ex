defmodule ZanshinApiWeb.TournamentController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Competitions
  alias ZanshinApi.Competitions.Tournament

  def index(conn, _params) do
    data = Competitions.list_tournaments() |> Enum.map(&serialize/1)
    json(conn, %{data: data})
  end

  def create(conn, params) do
    with :ok <- authorize_write(conn),
         {:ok, tournament} <- Competitions.create_tournament(params) do
      conn
      |> put_status(:created)
      |> json(%{data: serialize(tournament)})
    else
      {:error, :forbidden} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "forbidden"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_tournament_payload", details: changeset_errors(changeset)})
    end
  end

  defp serialize(%Tournament{} = tournament) do
    %{
      id: tournament.id,
      name: tournament.name,
      location: tournament.location,
      starts_on: tournament.starts_on
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
