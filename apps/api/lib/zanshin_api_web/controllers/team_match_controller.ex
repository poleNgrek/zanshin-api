defmodule ZanshinApiWeb.TeamMatchController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Teams
  alias ZanshinApi.Teams.TeamMatch

  def index(conn, %{"division_id" => division_id}) do
    data = Teams.list_team_matches_by_division(division_id) |> Enum.map(&serialize/1)
    json(conn, %{data: data})
  end

  def create(conn, params) do
    with :ok <- authorize_write(conn),
         {:ok, match} <- Teams.create_team_match(params) do
      conn
      |> put_status(:created)
      |> json(%{data: serialize(match)})
    else
      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "forbidden"})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_team_match_payload", details: changeset_errors(changeset)})

      {:error, reason} when is_atom(reason) ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: Atom.to_string(reason)})
    end
  end

  defp authorize_write(conn) do
    if conn.assigns[:current_role] in [:admin, :timekeeper], do: :ok, else: {:error, :forbidden}
  end

  defp serialize(%TeamMatch{} = match) do
    %{
      id: match.id,
      division_id: match.division_id,
      team_a_id: match.team_a_id,
      team_b_id: match.team_b_id,
      state: to_string(match.state),
      team_a_wins: match.team_a_wins,
      team_b_wins: match.team_b_wins,
      team_a_ippon: match.team_a_ippon,
      team_b_ippon: match.team_b_ippon,
      representative_match_required: match.representative_match_required,
      representative_winner_team_id: match.representative_winner_team_id,
      winner_team_id: match.winner_team_id,
      loser_team_id: match.loser_team_id
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
