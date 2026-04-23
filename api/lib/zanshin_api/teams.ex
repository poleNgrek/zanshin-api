defmodule ZanshinApi.Teams do
  @moduledoc "Team context for team competition lineups."

  import Ecto.Query, warn: false
  alias ZanshinApi.Competitions.Division
  alias ZanshinApi.Realtime.AdminBroadcaster
  alias ZanshinApi.Repo
  alias ZanshinApi.Teams.{Team, TeamMatch, TeamMember}

  def create_team(attrs) do
    %Team{}
    |> Team.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, team} ->
        division = Repo.get(Division, team.division_id)

        AdminBroadcaster.broadcast("admin_team_created", %{
          tournament_id: division && division.tournament_id,
          division_id: team.division_id,
          team_id: team.id,
          team_name: team.name
        })

        {:ok, team}

      error ->
        error
    end
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
    |> case do
      {:ok, member} ->
        team = Repo.get(Team, member.team_id)
        division = team && Repo.get(Division, team.division_id)

        AdminBroadcaster.broadcast("admin_team_member_added", %{
          tournament_id: division && division.tournament_id,
          division_id: team && team.division_id,
          team_id: member.team_id,
          competitor_id: member.competitor_id
        })

        {:ok, member}

      error ->
        error
    end
  end

  def list_team_members(team_id) do
    TeamMember
    |> where([m], m.team_id == ^team_id)
    |> order_by([m], asc: m.position)
    |> Repo.all()
  end

  def create_team_match(attrs) do
    with :ok <- ensure_team_match_invariants(attrs) do
      attrs = with_team_match_outcome(attrs)

      %TeamMatch{}
      |> TeamMatch.changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, team_match} ->
          division = Repo.get(Division, team_match.division_id)

          AdminBroadcaster.broadcast("admin_team_match_created", %{
            tournament_id: division && division.tournament_id,
            division_id: team_match.division_id,
            team_match_id: team_match.id
          })

          {:ok, team_match}

        error ->
          error
      end
    end
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

  defp ensure_team_match_invariants(attrs) do
    division_id = Map.get(attrs, "division_id") || Map.get(attrs, :division_id)
    team_a_id = Map.get(attrs, "team_a_id") || Map.get(attrs, :team_a_id)
    team_b_id = Map.get(attrs, "team_b_id") || Map.get(attrs, :team_b_id)

    representative_winner_team_id =
      Map.get(attrs, "representative_winner_team_id") ||
        Map.get(attrs, :representative_winner_team_id)

    with :ok <- ensure_team_in_division(team_a_id, division_id, :team_a_not_in_division),
         :ok <- ensure_team_in_division(team_b_id, division_id, :team_b_not_in_division),
         :ok <-
           ensure_representative_winner_participates(
             representative_winner_team_id,
             team_a_id,
             team_b_id
           ) do
      :ok
    end
  end

  defp ensure_team_in_division(nil, _division_id, _error), do: :ok
  defp ensure_team_in_division(_team_id, nil, _error), do: :ok

  defp ensure_team_in_division(team_id, division_id, error) do
    case Repo.get(Team, team_id) do
      nil -> :ok
      %Team{division_id: ^division_id} -> :ok
      _ -> {:error, error}
    end
  end

  defp ensure_representative_winner_participates(nil, _team_a_id, _team_b_id), do: :ok

  defp ensure_representative_winner_participates(
         representative_winner_team_id,
         team_a_id,
         team_b_id
       ) do
    if representative_winner_team_id in [team_a_id, team_b_id] do
      :ok
    else
      {:error, :representative_winner_not_in_match}
    end
  end
end
