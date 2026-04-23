defmodule ZanshinApi.CompetitionsTest do
  use ZanshinApi.DataCase, async: true

  alias ZanshinApi.Competitions
  alias ZanshinApi.Matches.Match
  alias ZanshinApi.Matches.ScoreEvent
  alias ZanshinApi.Repo
  import ZanshinApi.CompetitionsFixtures

  test "create_tournament/1 persists tournament" do
    assert {:ok, tournament} = Competitions.create_tournament(%{"name" => "Regional Open"})
    assert tournament.name == "Regional Open"
  end

  test "create_competitor/1 accepts photo_url alias into avatar_url" do
    assert {:ok, competitor} =
             Competitions.create_competitor(%{
               "display_name" => "Photo Competitor",
               "photo_url" => "https://cdn.example.com/photo.png"
             })

    assert competitor.avatar_url == "https://cdn.example.com/photo.png"
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

  test "bracket graph model stores ordered rounds slots and links" do
    tournament = tournament_fixture()
    division = division_fixture(tournament, %{"format" => "bracket"})

    assert {:ok, round_1} =
             Competitions.create_bracket_round(%{
               "division_id" => division.id,
               "round_number" => 1,
               "label" => "Semifinals"
             })

    assert {:ok, round_2} =
             Competitions.create_bracket_round(%{
               "division_id" => division.id,
               "round_number" => 2,
               "label" => "Final"
             })

    assert {:ok, slot_1} =
             Competitions.create_bracket_slot(%{"round_id" => round_1.id, "slot_number" => 1})

    assert {:ok, slot_2} =
             Competitions.create_bracket_slot(%{"round_id" => round_1.id, "slot_number" => 2})

    assert {:ok, final_slot} =
             Competitions.create_bracket_slot(%{"round_id" => round_2.id, "slot_number" => 1})

    assert {:ok, _l1} =
             Competitions.create_bracket_link(%{
               "from_slot_id" => slot_1.id,
               "to_slot_id" => final_slot.id,
               "outcome" => "winner"
             })

    assert {:ok, _l2} =
             Competitions.create_bracket_link(%{
               "from_slot_id" => slot_2.id,
               "to_slot_id" => final_slot.id,
               "outcome" => "winner"
             })

    rounds = Competitions.list_bracket_rounds(division.id)
    assert Enum.map(rounds, & &1.id) == [round_1.id, round_2.id]

    round_1_slots = Competitions.list_bracket_slots(round_1.id)
    assert Enum.map(round_1_slots, & &1.id) == [slot_1.id, slot_2.id]
  end

  test "bracket_traversal/1 returns graph envelope for division" do
    tournament = tournament_fixture()
    division = division_fixture(tournament, %{"format" => "bracket"})

    {:ok, round_1} =
      Competitions.create_bracket_round(%{
        "division_id" => division.id,
        "round_number" => 1,
        "label" => "Semifinals"
      })

    {:ok, round_2} =
      Competitions.create_bracket_round(%{
        "division_id" => division.id,
        "round_number" => 2,
        "label" => "Final"
      })

    {:ok, slot_1} =
      Competitions.create_bracket_slot(%{"round_id" => round_1.id, "slot_number" => 1})

    {:ok, slot_2} =
      Competitions.create_bracket_slot(%{"round_id" => round_1.id, "slot_number" => 2})

    {:ok, final_slot} =
      Competitions.create_bracket_slot(%{"round_id" => round_2.id, "slot_number" => 1})

    {:ok, _link} =
      Competitions.create_bracket_link(%{
        "from_slot_id" => slot_1.id,
        "to_slot_id" => final_slot.id,
        "outcome" => "winner"
      })

    {:ok, _link2} =
      Competitions.create_bracket_link(%{
        "from_slot_id" => slot_2.id,
        "to_slot_id" => final_slot.id,
        "outcome" => "winner"
      })

    assert {:ok, graph} = Competitions.bracket_traversal(division.id)
    assert Enum.map(graph.rounds, & &1.round_number) == [1, 2]
    assert length(graph.slots) == 3
    assert length(graph.links) == 2
  end

  test "creates shinpan assignment when schedule window has no conflicts" do
    tournament = tournament_fixture()
    shiaijo = shiaijo_fixture(tournament)
    shinpan = shinpan_fixture(tournament)

    assert {:ok, assignment} =
             Competitions.create_shinpan_assignment(%{
               "tournament_id" => tournament.id,
               "shiaijo_id" => shiaijo.id,
               "shinpan_id" => shinpan.id,
               "starts_at" => ~U[2026-04-23 09:00:00Z],
               "ends_at" => ~U[2026-04-23 09:30:00Z],
               "role" => "head"
             })

    assert assignment.tournament_id == tournament.id
    assert assignment.shiaijo_id == shiaijo.id
    assert assignment.shinpan_id == shinpan.id

    all_assignments = Competitions.list_shinpan_assignments(tournament.id)
    assert Enum.any?(all_assignments, &(&1.id == assignment.id))
  end

  test "rejects scheduling conflicts for shinpan and shiaijo overlaps" do
    tournament = tournament_fixture()
    shiaijo_a = shiaijo_fixture(tournament, %{"name" => "Area A"})
    shiaijo_b = shiaijo_fixture(tournament, %{"name" => "Area B"})
    shinpan_a = shinpan_fixture(tournament, %{"display_name" => "Ref A"})
    shinpan_b = shinpan_fixture(tournament, %{"display_name" => "Ref B"})

    _assignment =
      shinpan_assignment_fixture(tournament, shiaijo_a, shinpan_a, %{
        "starts_at" => ~U[2026-04-23 10:00:00Z],
        "ends_at" => ~U[2026-04-23 10:45:00Z]
      })

    assert {:error, :shinpan_schedule_conflict} =
             Competitions.create_shinpan_assignment(%{
               "tournament_id" => tournament.id,
               "shiaijo_id" => shiaijo_b.id,
               "shinpan_id" => shinpan_a.id,
               "starts_at" => ~U[2026-04-23 10:15:00Z],
               "ends_at" => ~U[2026-04-23 10:30:00Z]
             })

    assert {:error, :shiaijo_schedule_conflict} =
             Competitions.create_shinpan_assignment(%{
               "tournament_id" => tournament.id,
               "shiaijo_id" => shiaijo_a.id,
               "shinpan_id" => shinpan_b.id,
               "starts_at" => ~U[2026-04-23 10:20:00Z],
               "ends_at" => ~U[2026-04-23 10:40:00Z]
             })
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

  test "compute_division_results/1 derives gold silver and dual bronze from bracket matches" do
    tournament = tournament_fixture()
    division = division_fixture(tournament, %{"format" => "bracket"})
    c1 = competitor_fixture()
    c2 = competitor_fixture()
    c3 = competitor_fixture()
    c4 = competitor_fixture()

    _semi_1 = completed_match_fixture(tournament, division, c1, c2, 2, 0)
    _semi_2 = completed_match_fixture(tournament, division, c3, c4, 2, 1)
    _final = completed_match_fixture(tournament, division, c1, c3, 2, 1)

    assert {:ok, results} = Competitions.compute_division_results(division.id)
    assert length(results) == 4
    assert Enum.count(results, &(&1.medal == :bronze)) == 2
    assert Enum.any?(results, &(&1.medal == :gold and &1.competitor_id == c1.id))
    assert Enum.any?(results, &(&1.medal == :silver and &1.competitor_id == c3.id))
  end

  test "export_tournament_snapshot/1 returns nested tournament data" do
    tournament = tournament_fixture()
    division = division_fixture(tournament)
    _rules = division_rule_fixture(division, %{"age_group" => "adult"})
    _stage = division_stage_fixture(division, %{"stage_type" => "knockout", "sequence" => 1})
    competitor = competitor_fixture(%{"avatar_url" => "https://cdn.example.com/a.png"})
    _match = completed_match_fixture(tournament, division, competitor, competitor_fixture(), 2, 1)

    assert {:ok, snapshot} = Competitions.export_tournament_snapshot(tournament.id)
    assert snapshot.metadata.schema_version == 1
    assert snapshot.tournament.id == tournament.id
    assert Enum.any?(snapshot.divisions, &(&1.id == division.id))
    assert Enum.any?(snapshot.competitors, &(&1.id == competitor.id))
    assert length(snapshot.matches) >= 1
  end

  test "compute_division_results/1 derives team podium and supports representative match" do
    tournament = tournament_fixture()
    division = division_fixture(tournament, %{"format" => "team"})
    t1 = team_fixture(division)
    t2 = team_fixture(division)
    t3 = team_fixture(division)
    t4 = team_fixture(division)

    _semi_1 = team_match_fixture(division, t1, t2, %{"team_a_wins" => 3, "team_b_wins" => 2})

    _semi_2 =
      team_match_fixture(division, t3, t4, %{
        "team_a_wins" => 2,
        "team_b_wins" => 2,
        "representative_match_required" => true,
        "representative_winner_team_id" => t3.id
      })

    _final = team_match_fixture(division, t1, t3, %{"team_a_wins" => 1, "team_b_wins" => 3})

    assert {:ok, results} = Competitions.compute_division_results(division.id)
    assert Enum.any?(results, &(&1.medal == :gold and &1.team_id == t3.id))
    assert Enum.any?(results, &(&1.medal == :silver and &1.team_id == t1.id))
    assert Enum.count(results, &(&1.medal == :bronze)) == 2
  end

  defp completed_match_fixture(tournament, division, aka, shiro, aka_points, shiro_points) do
    {:ok, match} =
      ZanshinApi.Matches.create_match(%{
        "tournament_id" => tournament.id,
        "division_id" => division.id,
        "aka_competitor_id" => aka.id,
        "shiro_competitor_id" => shiro.id
      })

    {:ok, completed} = match |> Match.transition_changeset(%{state: :completed}) |> Repo.update()

    if aka_points > 0 do
      Enum.each(1..aka_points, fn _ ->
        %ScoreEvent{}
        |> ScoreEvent.changeset(%{
          "match_id" => completed.id,
          "score_type" => "ippon",
          "side" => "aka",
          "target" => "men",
          "actor_role" => "admin"
        })
        |> Repo.insert!()
      end)
    end

    if shiro_points > 0 do
      Enum.each(1..shiro_points, fn _ ->
        %ScoreEvent{}
        |> ScoreEvent.changeset(%{
          "match_id" => completed.id,
          "score_type" => "ippon",
          "side" => "shiro",
          "target" => "men",
          "actor_role" => "admin"
        })
        |> Repo.insert!()
      end)
    end

    completed
  end
end
