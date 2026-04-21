defmodule ZanshinApiWeb.DivisionMedalResultController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Competitions
  alias ZanshinApi.Competitions.DivisionMedalResult

  def index(conn, %{"division_id" => division_id}) do
    data = Competitions.list_division_medal_results(division_id) |> Enum.map(&serialize/1)
    json(conn, %{data: data})
  end

  def create(conn, params) do
    with :ok <- authorize_write(conn),
         {:ok, result} <- Competitions.create_division_medal_result(params) do
      conn
      |> put_status(:created)
      |> json(%{data: serialize(result)})
    else
      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "forbidden"})

      {:error, reason} when is_atom(reason) ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: Atom.to_string(reason)})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_division_medal_payload", details: changeset_errors(changeset)})
    end
  end

  defp authorize_write(conn) do
    if conn.assigns[:current_role] in [:admin, :timekeeper], do: :ok, else: {:error, :forbidden}
  end

  defp serialize(%DivisionMedalResult{} = result) do
    %{
      id: result.id,
      division_id: result.division_id,
      place: result.place,
      medal: to_string(result.medal),
      competitor_id: result.competitor_id,
      team_id: result.team_id
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
