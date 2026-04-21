defmodule ZanshinApiWeb.TeamController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Teams
  alias ZanshinApi.Teams.{Team, TeamMember}

  def index(conn, %{"division_id" => division_id}) do
    teams = Teams.list_teams_by_division(division_id)
    json(conn, %{data: Enum.map(teams, &serialize_team/1)})
  end

  def create(conn, %{"division_id" => division_id, "name" => name}) do
    with :ok <- authorize_write(conn),
         {:ok, team} <- Teams.create_team(%{"division_id" => division_id, "name" => name}) do
      conn
      |> put_status(:created)
      |> json(%{data: serialize_team(team)})
    else
      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "forbidden"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_team_payload", details: changeset_errors(changeset)})
    end
  end

  def add_member(conn, %{
        "id" => team_id,
        "competitor_id" => competitor_id,
        "position" => position
      }) do
    with :ok <- authorize_write(conn),
         {:ok, member} <-
           Teams.add_team_member(%{
             "team_id" => team_id,
             "competitor_id" => competitor_id,
             "position" => position
           }) do
      conn
      |> put_status(:created)
      |> json(%{data: serialize_member(member)})
    else
      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "forbidden"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_team_member_payload", details: changeset_errors(changeset)})
    end
  end

  def members(conn, %{"id" => team_id}) do
    members = Teams.list_team_members(team_id)
    json(conn, %{data: Enum.map(members, &serialize_member/1)})
  end

  defp authorize_write(conn) do
    if conn.assigns[:current_role] in [:admin, :timekeeper], do: :ok, else: {:error, :forbidden}
  end

  defp serialize_team(%Team{} = team) do
    %{id: team.id, division_id: team.division_id, name: team.name}
  end

  defp serialize_member(%TeamMember{} = member) do
    %{
      id: member.id,
      team_id: member.team_id,
      competitor_id: member.competitor_id,
      position: to_string(member.position)
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
