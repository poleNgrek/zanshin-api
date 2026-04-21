defmodule ZanshinApi.CompetitionsFixtures do
  @moduledoc false

  alias ZanshinApi.Competitions
  alias ZanshinApi.Teams

  def tournament_fixture(overrides \\ %{}) do
    attrs =
      Map.merge(
        %{"name" => "Spring Kendo Cup", "location" => "Budapest", "starts_on" => ~D[2026-06-01]},
        overrides
      )

    {:ok, tournament} = Competitions.create_tournament(attrs)
    tournament
  end

  def division_fixture(tournament, overrides \\ %{}) do
    attrs =
      Map.merge(
        %{"tournament_id" => tournament.id, "name" => "Open", "format" => "bracket"},
        overrides
      )

    {:ok, division} = Competitions.create_division(attrs)
    division
  end

  def competitor_fixture(overrides \\ %{}) do
    attrs =
      Map.merge(
        %{"display_name" => "Competitor #{System.unique_integer([:positive])}"},
        overrides
      )

    {:ok, competitor} = Competitions.create_competitor(attrs)
    competitor
  end

  def division_rule_fixture(division, overrides \\ %{}) do
    attrs =
      Map.merge(
        %{
          "category_type" => "open",
          "age_group" => "open",
          "allow_tsuki" => true,
          "match_duration_seconds" => 300
        },
        overrides
      )

    {:ok, rules} = Competitions.upsert_division_rules(division.id, attrs)
    rules
  end

  def division_stage_fixture(division, overrides \\ %{}) do
    attrs =
      Map.merge(
        %{
          "division_id" => division.id,
          "stage_type" => "round_robin",
          "sequence" => 1
        },
        overrides
      )

    {:ok, stage} = Competitions.create_division_stage(attrs)
    stage
  end

  def team_fixture(division, overrides \\ %{}) do
    attrs =
      Map.merge(
        %{"division_id" => division.id, "name" => "Team #{System.unique_integer([:positive])}"},
        overrides
      )

    {:ok, team} = Teams.create_team(attrs)
    team
  end

  def team_member_fixture(team, competitor, overrides \\ %{}) do
    attrs =
      Map.merge(
        %{"team_id" => team.id, "competitor_id" => competitor.id, "position" => "taisho"},
        overrides
      )

    {:ok, member} = Teams.add_team_member(attrs)
    member
  end

  def division_medal_result_fixture(division, overrides \\ %{}) do
    attrs =
      Map.merge(
        %{"division_id" => division.id, "place" => 1},
        overrides
      )

    {:ok, result} = Competitions.create_division_medal_result(attrs)
    result
  end

  def division_special_award_fixture(division, overrides \\ %{}) do
    attrs =
      Map.merge(
        %{"division_id" => division.id, "award_type" => "fighting_spirit"},
        overrides
      )

    {:ok, award} = Competitions.create_division_special_award(attrs)
    award
  end
end
