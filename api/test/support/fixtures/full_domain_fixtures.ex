defmodule ZanshinApi.FullDomainFixtures do
  @moduledoc false

  alias ZanshinApi.Competitions
  alias ZanshinApi.Gradings
  alias ZanshinApi.Matches

  import ZanshinApi.CompetitionsFixtures

  @team_positions ~w(senpo jiho chuken fukusho taisho)

  def full_tournament_fixture(overrides \\ %{}) do
    tournament = tournament_fixture(Map.get(overrides, :tournament, %{}))

    individual_division =
      division_fixture(
        tournament,
        Map.merge(
          %{"name" => "Senior Individual", "format" => "bracket"},
          Map.get(overrides, :individual_division, %{})
        )
      )

    team_division =
      division_fixture(
        tournament,
        Map.merge(
          %{"name" => "Senior Team", "format" => "team"},
          Map.get(overrides, :team_division, %{})
        )
      )

    individual_rules =
      division_rule_fixture(
        individual_division,
        Map.merge(
          %{
            "category_type" => "open",
            "age_group" => "adult",
            "min_age" => 18,
            "max_age" => 49,
            "allow_tsuki" => true,
            "match_duration_seconds" => 300
          },
          Map.get(overrides, :individual_rules, %{})
        )
      )

    team_rules =
      division_rule_fixture(
        team_division,
        Map.merge(
          %{
            "category_type" => "open",
            "age_group" => "adult",
            "allow_tsuki" => true,
            "team_size" => 5,
            "representative_match_enabled" => true
          },
          Map.get(overrides, :team_rules, %{})
        )
      )

    individual_stages = [
      division_stage_fixture(
        individual_division,
        %{"stage_type" => "pool_to_knockout", "sequence" => 1, "advances_count" => 8}
      ),
      division_stage_fixture(
        individual_division,
        %{"stage_type" => "knockout", "sequence" => 2}
      )
    ]

    team_stages = [
      division_stage_fixture(team_division, %{"stage_type" => "round_robin", "sequence" => 1}),
      division_stage_fixture(
        team_division,
        %{"stage_type" => "knockout", "sequence" => 2, "advances_count" => 2}
      )
    ]

    competitors = build_competitors()
    competitor_index = Map.new(competitors, &{&1.display_name, &1})

    individual_match =
      create_completed_match!(
        tournament.id,
        individual_division.id,
        competitor_index["Kenshi Alpha"].id,
        competitor_index["Kenshi Beta"].id
      )

    team_a = team_fixture(team_division, %{"name" => "Team Akatsuki"})
    team_b = team_fixture(team_division, %{"name" => "Team Byakko"})

    Enum.zip(@team_positions, Enum.slice(competitors, 0, 5))
    |> Enum.each(fn {position, competitor} ->
      team_member_fixture(team_a, competitor, %{"position" => position})
    end)

    Enum.zip(@team_positions, Enum.slice(competitors, 5, 5))
    |> Enum.each(fn {position, competitor} ->
      team_member_fixture(team_b, competitor, %{"position" => position})
    end)

    team_match =
      team_match_fixture(team_division, team_a, team_b, %{
        "state" => "completed",
        "team_a_wins" => 3,
        "team_b_wins" => 2,
        "team_a_ippon" => 7,
        "team_b_ippon" => 5
      })

    medals =
      create_individual_medals!(individual_division.id, [
        competitor_index["Kenshi Alpha"].id,
        competitor_index["Kenshi Beta"].id,
        competitor_index["Kenshi Gamma"].id,
        competitor_index["Kenshi Delta"].id
      ])

    team_medals = create_team_medals!(team_division.id, [team_a.id, team_b.id])

    individual_award =
      division_special_award_fixture(individual_division, %{
        "competitor_id" => competitor_index["Kenshi Eta"].id,
        "award_type" => "fighting_spirit"
      })

    team_award =
      division_special_award_fixture(team_division, %{
        "team_id" => team_a.id,
        "competitor_id" => competitor_index["Kenshi Alpha"].id,
        "award_type" => "fighting_spirit"
      })

    grading = create_grading_fixture!(tournament.id, competitor_index["Kenshi Alpha"].id)

    %{
      tournament: tournament,
      divisions: %{individual: individual_division, team: team_division},
      rules: %{individual: individual_rules, team: team_rules},
      stages: %{individual: individual_stages, team: team_stages},
      competitors: competitors,
      matches: %{individual: individual_match},
      teams: %{a: team_a, b: team_b},
      team_matches: [team_match],
      medal_results: %{individual: medals, team: team_medals},
      special_awards: %{individual: individual_award, team: team_award},
      grading: grading
    }
  end

  defp build_competitors do
    [
      %{
        "display_name" => "Kenshi Alpha",
        "grade_type" => "dan",
        "grade_value" => 4,
        "preferred_stance" => "chudan"
      },
      %{
        "display_name" => "Kenshi Beta",
        "grade_type" => "dan",
        "grade_value" => 3,
        "preferred_stance" => "jodan_left"
      },
      %{
        "display_name" => "Kenshi Gamma",
        "grade_type" => "dan",
        "grade_value" => 3,
        "preferred_stance" => "jodan_right"
      },
      %{
        "display_name" => "Kenshi Delta",
        "grade_type" => "dan",
        "grade_value" => 2,
        "preferred_stance" => "nito"
      },
      %{
        "display_name" => "Kenshi Epsilon",
        "grade_type" => "kyu",
        "grade_value" => 1,
        "preferred_stance" => "chudan"
      },
      %{
        "display_name" => "Kenshi Zeta",
        "grade_type" => "dan",
        "grade_value" => 4,
        "preferred_stance" => "chudan"
      },
      %{
        "display_name" => "Kenshi Eta",
        "grade_type" => "dan",
        "grade_value" => 3,
        "preferred_stance" => "gedan"
      },
      %{
        "display_name" => "Kenshi Theta",
        "grade_type" => "dan",
        "grade_value" => 2,
        "preferred_stance" => "hasso"
      },
      %{
        "display_name" => "Kenshi Iota",
        "grade_type" => "kyu",
        "grade_value" => 2,
        "preferred_stance" => "waki"
      },
      %{
        "display_name" => "Kenshi Kappa",
        "grade_type" => "dan",
        "grade_value" => 5,
        "preferred_stance" => "other"
      }
    ]
    |> Enum.map(&competitor_fixture/1)
  end

  defp create_completed_match!(tournament_id, division_id, aka_competitor_id, shiro_competitor_id) do
    {:ok, match} =
      Matches.create_match(%{
        "tournament_id" => tournament_id,
        "division_id" => division_id,
        "aka_competitor_id" => aka_competitor_id,
        "shiro_competitor_id" => shiro_competitor_id
      })

    {:ok, _prepared} = Matches.transition_match(match.id, :prepare, :admin)
    {:ok, _started} = Matches.transition_match(match.id, :start, :admin)
    {:ok, _} = Matches.record_score_event(match.id, :ippon, :aka, :men, :shinpan)
    {:ok, _} = Matches.record_score_event(match.id, :hansoku, :shiro, nil, :shinpan)
    {:ok, completed_match} = Matches.transition_match(match.id, :complete, :admin)

    completed_match
  end

  defp create_individual_medals!(division_id, [gold, silver, bronze_a, bronze_b]) do
    [
      create_medal!(division_id, 1, gold),
      create_medal!(division_id, 2, silver),
      create_medal!(division_id, 3, bronze_a),
      create_medal!(division_id, 3, bronze_b)
    ]
  end

  defp create_medal!(division_id, place, competitor_id) do
    {:ok, medal} =
      Competitions.create_division_medal_result(%{
        "division_id" => division_id,
        "place" => place,
        "competitor_id" => competitor_id
      })

    medal
  end

  defp create_team_medals!(division_id, [gold_team_id, silver_team_id]) do
    {:ok, gold} =
      Competitions.create_division_medal_result(%{
        "division_id" => division_id,
        "place" => 1,
        "team_id" => gold_team_id
      })

    {:ok, silver} =
      Competitions.create_division_medal_result(%{
        "division_id" => division_id,
        "place" => 2,
        "team_id" => silver_team_id
      })

    [gold, silver]
  end

  defp create_grading_fixture!(tournament_id, competitor_id) do
    {:ok, session} =
      Gradings.create_session(%{
        "tournament_id" => tournament_id,
        "name" => "Spring Dan Shinsa",
        "held_on" => ~D[2026-06-02],
        "written_required" => true,
        "required_pass_votes" => 2
      })

    {:ok, head_examiner} =
      Gradings.create_examiner(%{
        "display_name" => "Examiner Head",
        "grade" => "7dan",
        "title" => "kyoshi"
      })

    {:ok, member_examiner} =
      Gradings.create_examiner(%{
        "display_name" => "Examiner Member",
        "grade" => "6dan",
        "title" => "renshi"
      })

    {:ok, head_assignment} =
      Gradings.assign_examiner_to_session(session.id, %{
        "examiner_id" => head_examiner.id,
        "role" => "head"
      })

    {:ok, member_assignment} =
      Gradings.assign_examiner_to_session(session.id, %{
        "examiner_id" => member_examiner.id,
        "role" => "member"
      })

    {:ok, result} =
      Gradings.create_result(session.id, %{
        "competitor_id" => competitor_id,
        "target_grade" => "5dan",
        "declared_stance" => "chudan"
      })

    votes =
      for {examiner, part} <- [
            {head_examiner, "jitsugi"},
            {member_examiner, "jitsugi"},
            {head_examiner, "kata"},
            {member_examiner, "kata"},
            {head_examiner, "written"},
            {member_examiner, "written"}
          ] do
        {:ok, vote} =
          Gradings.create_vote(result.id, %{
            "examiner_id" => examiner.id,
            "part" => part,
            "decision" => "pass"
          })

        vote
      end

    {:ok, note} =
      Gradings.create_note(result.id, %{
        "examiner_id" => head_examiner.id,
        "part" => "kata",
        "note" => "Stable kamae and clean hasuji."
      })

    {:ok, computed_result} = Gradings.compute_result_decision(result.id)
    {:ok, finalized_result} = Gradings.finalize_result(result.id, :admin)

    %{
      session: session,
      examiners: [head_examiner, member_examiner],
      panel_assignments: [head_assignment, member_assignment],
      result: finalized_result,
      computed_result: computed_result,
      votes: votes,
      note: note
    }
  end
end
