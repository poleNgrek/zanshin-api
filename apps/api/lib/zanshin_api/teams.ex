defmodule ZanshinApi.Teams do
  @moduledoc "Team context for team competition lineups."

  import Ecto.Query, warn: false
  alias ZanshinApi.Repo
  alias ZanshinApi.Teams.{Team, TeamMember}

  def create_team(attrs) do
    %Team{}
    |> Team.changeset(attrs)
    |> Repo.insert()
  end

  def list_teams_by_division(division_id) do
    Team
    |> where([t], t.division_id == ^division_id)
    |> order_by([t], asc: t.name)
    |> Repo.all()
  end

  def add_team_member(attrs) do
    %TeamMember{}
    |> TeamMember.changeset(attrs)
    |> Repo.insert()
  end

  def list_team_members(team_id) do
    TeamMember
    |> where([m], m.team_id == ^team_id)
    |> order_by([m], asc: m.position)
    |> Repo.all()
  end
end
