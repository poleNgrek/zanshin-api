alias ZanshinApi.Competitions
alias ZanshinApi.Gradings
alias ZanshinApi.Matches
alias ZanshinApi.Repo
alias ZanshinApi.Teams

team_positions = ~w(senpo jiho chuken fukusho taisho)

if Repo.aggregate(ZanshinApi.Competitions.Tournament, :count) > 0 do
  IO.puts("Skipping seed: tournaments already exist. Reset DB if you want a clean seed run.")
else
  {:ok, tournament} =
    Competitions.create_tournament(%{
      "name" => "Zanshin Spring Open 2026",
      "location" => "Kyoto Budokan",
      "starts_on" => ~D[2026-05-18]
    })

  {:ok, individual_division} =
    Competitions.create_division(%{
      "tournament_id" => tournament.id,
      "name" => "Adult Individual",
      "format" => "bracket"
    })

  {:ok, team_division} =
    Competitions.create_division(%{
      "tournament_id" => tournament.id,
      "name" => "Adult Team",
      "format" => "team"
    })

  {:ok, _individual_rules} =
    Competitions.upsert_division_rules(individual_division.id, %{
      "category_type" => "open",
      "age_group" => "adult",
      "min_age" => 18,
      "max_age" => 49,
      "allow_tsuki" => true,
      "match_duration_seconds" => 300
    })

  {:ok, _team_rules} =
    Competitions.upsert_division_rules(team_division.id, %{
      "category_type" => "open",
      "age_group" => "adult",
      "allow_tsuki" => true,
      "team_size" => 5,
      "representative_match_enabled" => true
    })

  {:ok, _} =
    Competitions.create_division_stage(%{
      "division_id" => individual_division.id,
      "stage_type" => "pool_to_knockout",
      "sequence" => 1,
      "advances_count" => 8
    })

  {:ok, _} =
    Competitions.create_division_stage(%{
      "division_id" => individual_division.id,
      "stage_type" => "knockout",
      "sequence" => 2
    })

  {:ok, _} =
    Competitions.create_division_stage(%{
      "division_id" => team_division.id,
      "stage_type" => "round_robin",
      "sequence" => 1
    })

  {:ok, _} =
    Competitions.create_division_stage(%{
      "division_id" => team_division.id,
      "stage_type" => "knockout",
      "sequence" => 2,
      "advances_count" => 2
    })

  competitor_payloads = [
    %{"display_name" => "Kenshi Alpha", "grade_type" => "dan", "grade_value" => 4, "preferred_stance" => "chudan"},
    %{"display_name" => "Kenshi Beta", "grade_type" => "dan", "grade_value" => 3, "preferred_stance" => "jodan_left"},
    %{"display_name" => "Kenshi Gamma", "grade_type" => "dan", "grade_value" => 3, "preferred_stance" => "jodan_right"},
    %{"display_name" => "Kenshi Delta", "grade_type" => "dan", "grade_value" => 2, "preferred_stance" => "nito"},
    %{"display_name" => "Kenshi Epsilon", "grade_type" => "kyu", "grade_value" => 1, "preferred_stance" => "chudan"},
    %{"display_name" => "Kenshi Zeta", "grade_type" => "dan", "grade_value" => 4, "preferred_stance" => "chudan"},
    %{"display_name" => "Kenshi Eta", "grade_type" => "dan", "grade_value" => 3, "preferred_stance" => "gedan"},
    %{"display_name" => "Kenshi Theta", "grade_type" => "dan", "grade_value" => 2, "preferred_stance" => "hasso"},
    %{"display_name" => "Kenshi Iota", "grade_type" => "kyu", "grade_value" => 2, "preferred_stance" => "waki"},
    %{"display_name" => "Kenshi Kappa", "grade_type" => "dan", "grade_value" => 5, "preferred_stance" => "other"}
  ]

  competitors =
    competitor_payloads
    |> Enum.map(fn attrs ->
      {:ok, competitor} = Competitions.create_competitor(attrs)
      competitor
    end)

  competitor_by_name = Map.new(competitors, &{&1.display_name, &1})

  {:ok, match} =
    Matches.create_match(%{
      "tournament_id" => tournament.id,
      "division_id" => individual_division.id,
      "aka_competitor_id" => competitor_by_name["Kenshi Alpha"].id,
      "shiro_competitor_id" => competitor_by_name["Kenshi Beta"].id
    })

  {:ok, _} = Matches.transition_match(match.id, :prepare, :admin)
  {:ok, _} = Matches.transition_match(match.id, :start, :admin)
  {:ok, _} = Matches.record_score_event(match.id, :ippon, :aka, :men, :shinpan)
  {:ok, _} = Matches.record_score_event(match.id, :hansoku, :shiro, nil, :shinpan)
  {:ok, _} = Matches.transition_match(match.id, :complete, :admin)

  {:ok, team_a} =
    Teams.create_team(%{
      "division_id" => team_division.id,
      "name" => "Team Akatsuki"
    })

  {:ok, team_b} =
    Teams.create_team(%{
      "division_id" => team_division.id,
      "name" => "Team Byakko"
    })

  Enum.zip(team_positions, Enum.slice(competitors, 0, 5))
  |> Enum.each(fn {position, competitor} ->
    {:ok, _} =
      Teams.add_team_member(%{
        "team_id" => team_a.id,
        "competitor_id" => competitor.id,
        "position" => position
      })
  end)

  Enum.zip(team_positions, Enum.slice(competitors, 5, 5))
  |> Enum.each(fn {position, competitor} ->
    {:ok, _} =
      Teams.add_team_member(%{
        "team_id" => team_b.id,
        "competitor_id" => competitor.id,
        "position" => position
      })
  end)

  {:ok, _team_match} =
    Teams.create_team_match(%{
      "division_id" => team_division.id,
      "team_a_id" => team_a.id,
      "team_b_id" => team_b.id,
      "state" => "completed",
      "team_a_wins" => 3,
      "team_b_wins" => 2,
      "team_a_ippon" => 7,
      "team_b_ippon" => 5
    })

  {:ok, _} =
    Competitions.create_division_medal_result(%{
      "division_id" => individual_division.id,
      "place" => 1,
      "competitor_id" => competitor_by_name["Kenshi Alpha"].id
    })

  {:ok, _} =
    Competitions.create_division_medal_result(%{
      "division_id" => individual_division.id,
      "place" => 2,
      "competitor_id" => competitor_by_name["Kenshi Beta"].id
    })

  {:ok, _} =
    Competitions.create_division_medal_result(%{
      "division_id" => individual_division.id,
      "place" => 3,
      "competitor_id" => competitor_by_name["Kenshi Gamma"].id
    })

  {:ok, _} =
    Competitions.create_division_medal_result(%{
      "division_id" => individual_division.id,
      "place" => 3,
      "competitor_id" => competitor_by_name["Kenshi Delta"].id
    })

  {:ok, _} =
    Competitions.create_division_medal_result(%{
      "division_id" => team_division.id,
      "place" => 1,
      "team_id" => team_a.id
    })

  {:ok, _} =
    Competitions.create_division_medal_result(%{
      "division_id" => team_division.id,
      "place" => 2,
      "team_id" => team_b.id
    })

  {:ok, _} =
    Competitions.create_division_special_award(%{
      "division_id" => individual_division.id,
      "award_type" => "fighting_spirit",
      "competitor_id" => competitor_by_name["Kenshi Eta"].id
    })

  {:ok, _} =
    Competitions.create_division_special_award(%{
      "division_id" => team_division.id,
      "award_type" => "fighting_spirit",
      "competitor_id" => competitor_by_name["Kenshi Alpha"].id,
      "team_id" => team_a.id
    })

  {:ok, grading_session} =
    Gradings.create_session(%{
      "tournament_id" => tournament.id,
      "name" => "Spring Dan Shinsa",
      "held_on" => ~D[2026-05-20],
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

  {:ok, _} =
    Gradings.assign_examiner_to_session(grading_session.id, %{
      "examiner_id" => head_examiner.id,
      "role" => "head"
    })

  {:ok, _} =
    Gradings.assign_examiner_to_session(grading_session.id, %{
      "examiner_id" => member_examiner.id,
      "role" => "member"
    })

  {:ok, grading_result} =
    Gradings.create_result(grading_session.id, %{
      "competitor_id" => competitor_by_name["Kenshi Alpha"].id,
      "target_grade" => "5dan",
      "declared_stance" => "chudan"
    })

  for {examiner_id, part} <- [
        {head_examiner.id, "jitsugi"},
        {member_examiner.id, "jitsugi"},
        {head_examiner.id, "kata"},
        {member_examiner.id, "kata"},
        {head_examiner.id, "written"},
        {member_examiner.id, "written"}
      ] do
    {:ok, _} =
      Gradings.create_vote(grading_result.id, %{
        "examiner_id" => examiner_id,
        "part" => part,
        "decision" => "pass"
      })
  end

  {:ok, _} =
    Gradings.create_note(grading_result.id, %{
      "examiner_id" => head_examiner.id,
      "part" => "kata",
      "note" => "Stable pressure and timing."
    })

  {:ok, _} = Gradings.compute_result_decision(grading_result.id)
  {:ok, _} = Gradings.finalize_result(grading_result.id, :admin)

  IO.puts("Seeded full-domain sample dataset for #{tournament.name}.")
  IO.puts("Tournament ID: #{tournament.id}")
  IO.puts("Individual Division ID: #{individual_division.id}")
  IO.puts("Team Division ID: #{team_division.id}")
  IO.puts("Grading Session ID: #{grading_session.id}")
end
