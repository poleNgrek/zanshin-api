defmodule ZanshinApi.CompetitionsFixtures do
  @moduledoc false

  alias ZanshinApi.Competitions

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
end
