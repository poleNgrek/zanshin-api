defmodule ZanshinApi.CompetitionsTest do
  use ZanshinApi.DataCase, async: true

  alias ZanshinApi.Competitions
  import ZanshinApi.CompetitionsFixtures

  test "create_tournament/1 persists tournament" do
    assert {:ok, tournament} = Competitions.create_tournament(%{"name" => "Regional Open"})
    assert tournament.name == "Regional Open"
  end

  test "create_division/1 requires valid tournament reference" do
    assert {:error, changeset} =
             Competitions.create_division(%{
               "name" => "U18",
               "format" => "bracket",
               "tournament_id" => Ecto.UUID.generate()
             })

    assert "does not exist" in errors_on(changeset).tournament_id
  end

  test "list_divisions_by_tournament/1 returns only scoped records" do
    t1 = tournament_fixture(%{"name" => "Tournament One"})
    t2 = tournament_fixture(%{"name" => "Tournament Two"})
    d1 = division_fixture(t1, %{"name" => "Open"})
    _d2 = division_fixture(t2, %{"name" => "Women"})

    result = Competitions.list_divisions_by_tournament(t1.id)
    assert Enum.map(result, & &1.id) == [d1.id]
  end

  test "list_division_stages/1 returns progression plan by sequence" do
    tournament = tournament_fixture()
    division = division_fixture(tournament, %{"format" => "hybrid"})
    s1 = division_stage_fixture(division, %{"stage_type" => "round_robin", "sequence" => 1})
    s2 = division_stage_fixture(division, %{"stage_type" => "knockout", "sequence" => 2})

    result = Competitions.list_division_stages(division.id)
    assert Enum.map(result, & &1.id) == [s1.id, s2.id]
  end

  test "creates podium medals with two bronze entries and no fourth place" do
    tournament = tournament_fixture()
    division = division_fixture(tournament, %{"format" => "bracket"})
    c1 = competitor_fixture()
    c2 = competitor_fixture()
    c3 = competitor_fixture()
    c4 = competitor_fixture()

    assert {:ok, gold} =
             Competitions.create_division_medal_result(%{
               "division_id" => division.id,
               "place" => 1,
               "competitor_id" => c1.id
             })

    assert {:ok, silver} =
             Competitions.create_division_medal_result(%{
               "division_id" => division.id,
               "place" => 2,
               "competitor_id" => c2.id
             })

    assert {:ok, bronze_a} =
             Competitions.create_division_medal_result(%{
               "division_id" => division.id,
               "place" => 3,
               "competitor_id" => c3.id
             })

    assert {:ok, bronze_b} =
             Competitions.create_division_medal_result(%{
               "division_id" => division.id,
               "place" => 3,
               "competitor_id" => c4.id
             })

    assert gold.medal == :gold
    assert silver.medal == :silver
    assert bronze_a.medal == :bronze
    assert bronze_b.medal == :bronze

    assert {:error, :place_capacity_reached} =
             Competitions.create_division_medal_result(%{
               "division_id" => division.id,
               "place" => 3,
               "competitor_id" => competitor_fixture().id
             })

    assert {:error, :place_capacity_reached} =
             Competitions.create_division_medal_result(%{
               "division_id" => division.id,
               "place" => 1,
               "competitor_id" => competitor_fixture().id
             })
  end

  test "team divisions award medals to team and fighting spirit to one player" do
    tournament = tournament_fixture()
    division = division_fixture(tournament, %{"format" => "team"})
    competitor = competitor_fixture()
    team = team_fixture(division)
    _member = team_member_fixture(team, competitor)

    assert {:ok, medal_result} =
             Competitions.create_division_medal_result(%{
               "division_id" => division.id,
               "place" => 1,
               "team_id" => team.id
             })

    assert medal_result.team_id == team.id
    assert is_nil(medal_result.competitor_id)

    assert {:ok, award} =
             Competitions.create_division_special_award(%{
               "division_id" => division.id,
               "award_type" => "fighting_spirit",
               "team_id" => team.id,
               "competitor_id" => competitor.id
             })

    assert award.award_type == :fighting_spirit
    assert award.team_id == team.id
    assert award.competitor_id == competitor.id
  end
end
