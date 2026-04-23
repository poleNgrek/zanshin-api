defmodule ZanshinApiWeb.AdminChannelTest do
  use ZanshinApiWeb.ChannelCase, async: true

  alias ZanshinApi.Competitions
  alias ZanshinApi.Gradings
  alias ZanshinApiWeb.{AdminChannel, UserSocket}
  import ZanshinApi.CompetitionsFixtures

  test "joins admin tournament topic and receives tournament created event" do
    {:ok, _, socket} =
      UserSocket
      |> socket("admin-user-1", %{})
      |> subscribe_and_join(AdminChannel, "admin:all")

    assert {:ok, tournament} = Competitions.create_tournament(%{"name" => "Realtime Cup"})

    assert_push "admin_tournament_created", %{
      tournament_id: tournament_id,
      name: "Realtime Cup"
    }

    assert tournament_id == tournament.id
    assert socket.topic == "admin:all"
  end

  test "receives grading result finalized event on tournament topic" do
    tournament = tournament_fixture()
    competitor = competitor_fixture()

    {:ok, _, socket} =
      UserSocket
      |> socket("admin-user-2", %{})
      |> subscribe_and_join(AdminChannel, "admin:tournament:#{tournament.id}")

    assert {:ok, session} =
             Gradings.create_session(%{
               "tournament_id" => tournament.id,
               "name" => "Realtime Shinsa"
             })

    assert {:ok, result} =
             Gradings.create_result(session.id, %{
               "competitor_id" => competitor.id,
               "target_grade" => "3dan"
             })

    assert {:ok, _finalized} = Gradings.finalize_result(result.id, :admin)

    assert_push "admin_grading_result_finalized", %{
      tournament_id: tournament_id,
      grading_session_id: grading_session_id,
      grading_result_id: grading_result_id
    }

    assert tournament_id == tournament.id
    assert grading_session_id == session.id
    assert grading_result_id == result.id
    assert socket.topic == "admin:tournament:#{tournament.id}"
  end
end
