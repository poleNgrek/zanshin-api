defmodule ZanshinApi.GradingsTest do
  use ZanshinApi.DataCase, async: true

  alias ZanshinApi.Gradings
  alias ZanshinApi.Repo
  alias ZanshinApi.Grading.GradingResult
  import ZanshinApi.CompetitionsFixtures

  test "create_result/2 sets pending with carryover when kata fails" do
    tournament = tournament_fixture()

    {:ok, session} =
      Gradings.create_session(%{
        "tournament_id" => tournament.id,
        "name" => "Spring Dan Shinsa",
        "held_on" => ~D[2026-04-21],
        "written_required" => true
      })

    competitor = competitor_fixture()

    assert {:ok, result} =
             Gradings.create_result(session.id, %{
               "competitor_id" => competitor.id,
               "target_grade" => "4dan",
               "jitsugi_result" => "pass",
               "kata_result" => "fail",
               "written_result" => "pass",
               "declared_stance" => "chudan"
             })

    assert result.final_result == :pending
    assert result.carryover_until == ~D[2027-04-16]
  end

  test "create_result/2 allows pass with written waived when not required" do
    tournament = tournament_fixture()

    {:ok, session} =
      Gradings.create_session(%{
        "tournament_id" => tournament.id,
        "name" => "Summer Dan Shinsa",
        "held_on" => ~D[2026-07-10],
        "written_required" => false
      })

    competitor = competitor_fixture()

    assert {:ok, result} =
             Gradings.create_result(session.id, %{
               "competitor_id" => competitor.id,
               "target_grade" => "3dan",
               "jitsugi_result" => "pass",
               "kata_result" => "pass"
             })

    assert result.final_result == :pass
    assert result.written_result == :waived
  end

  test "compute_result_decision/1 applies quorum and finalize_result/2 locks result" do
    tournament = tournament_fixture()
    competitor = competitor_fixture()

    {:ok, session} =
      Gradings.create_session(%{
        "tournament_id" => tournament.id,
        "name" => "Quorum Shinsa",
        "written_required" => true,
        "required_pass_votes" => 3
      })

    {:ok, examiner_a} = Gradings.create_examiner(%{"display_name" => "Examiner A"})
    {:ok, examiner_b} = Gradings.create_examiner(%{"display_name" => "Examiner B"})
    {:ok, examiner_c} = Gradings.create_examiner(%{"display_name" => "Examiner C"})

    {:ok, _assign_a} =
      Gradings.assign_examiner_to_session(session.id, %{
        "examiner_id" => examiner_a.id,
        "role" => "member"
      })

    {:ok, _assign_b} =
      Gradings.assign_examiner_to_session(session.id, %{
        "examiner_id" => examiner_b.id,
        "role" => "member"
      })

    {:ok, _assign_c} =
      Gradings.assign_examiner_to_session(session.id, %{
        "examiner_id" => examiner_c.id,
        "role" => "member"
      })

    {:ok, result} =
      Gradings.create_result(session.id, %{
        "competitor_id" => competitor.id,
        "target_grade" => "4dan"
      })

    for examiner <- [examiner_a, examiner_b, examiner_c] do
      {:ok, _} =
        Gradings.create_vote(result.id, %{
          "examiner_id" => examiner.id,
          "part" => "jitsugi",
          "decision" => "pass"
        })
    end

    for examiner <- [examiner_a, examiner_b, examiner_c] do
      {:ok, _} =
        Gradings.create_vote(result.id, %{
          "examiner_id" => examiner.id,
          "part" => "kata",
          "decision" => "pass"
        })
    end

    for examiner <- [examiner_a, examiner_b, examiner_c] do
      {:ok, _} =
        Gradings.create_vote(result.id, %{
          "examiner_id" => examiner.id,
          "part" => "written",
          "decision" => "pass"
        })
    end

    assert {:ok, computed} = Gradings.compute_result_decision(result.id)
    assert computed.final_result == :pass
    assert is_map(computed.decision_snapshot)

    assert {:ok, finalized} = Gradings.finalize_result(result.id, :admin)
    assert not is_nil(finalized.locked_at)
    assert not is_nil(finalized.finalized_at)

    assert {:error, :grading_result_locked} =
             Gradings.create_vote(finalized.id, %{
               "examiner_id" => examiner_a.id,
               "part" => "jitsugi",
               "decision" => "pass"
             })

    fresh = Repo.get!(GradingResult, finalized.id)
    assert fresh.final_result == :pass
  end
end
