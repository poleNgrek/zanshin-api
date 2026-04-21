defmodule ZanshinApi.Teams do
  @moduledoc "Team context for team competition lineups."

  import Ecto.Query, warn: false
  alias ZanshinApi.Repo
  alias ZanshinApi.Teams.{Team, TeamMatch, TeamMember}

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

  def create_team_match(attrs) do
    attrs = with_team_match_outcome(attrs)

    %TeamMatch{}
    |> TeamMatch.changeset(attrs)
    |> Repo.insert()
  end

  def list_team_matches_by_division(division_id) do
    TeamMatch
    |> where([m], m.division_id == ^division_id)
    |> order_by([m], asc: m.inserted_at)
    |> Repo.all()
  end

  defp with_team_match_outcome(attrs) do
    state = Map.get(attrs, "state") || Map.get(attrs, :state)

    if state in ["completed", :completed] do
      a_id = Map.get(attrs, "team_a_id") || Map.get(attrs, :team_a_id)
      b_id = Map.get(attrs, "team_b_id") || Map.get(attrs, :team_b_id)
      a_wins = Map.get(attrs, "team_a_wins") || Map.get(attrs, :team_a_wins) || 0
      b_wins = Map.get(attrs, "team_b_wins") || Map.get(attrs, :team_b_wins) || 0

      rep_winner =
        Map.get(attrs, "representative_winner_team_id") ||
          Map.get(attrs, :representative_winner_team_id)

      rep_required =
        Map.get(attrs, "representative_match_required") ||
          Map.get(attrs, :representative_match_required)

      {winner_id, loser_id} =
        cond do
          rep_required -> {rep_winner, if(rep_winner == a_id, do: b_id, else: a_id)}
          a_wins > b_wins -> {a_id, b_id}
          b_wins > a_wins -> {b_id, a_id}
          true -> {nil, nil}
        end

      attrs
      |> Map.put("winner_team_id", winner_id)
      |> Map.put("loser_team_id", loser_id)
    else
      attrs
    end
  end
end
