defmodule ZanshinApi.GradingsTest do
  use ZanshinApi.DataCase, async: true

  alias ZanshinApi.Gradings
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
end
