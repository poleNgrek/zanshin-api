defmodule ZanshinApiWeb.MatchChannelTest do
  use ZanshinApiWeb.ChannelCase, async: true

  alias ZanshinApi.Matches
  alias ZanshinApiWeb.{MatchChannel, UserSocket}
  import ZanshinApi.MatchesFixtures

  test "joins tournament and match topics and receives transition realtime event" do
    match = match_fixture()
    match_id = match.id
    tournament_id = match.tournament_id

    {:ok, _, tournament_socket} =
      UserSocket
      |> socket("user-1", %{})
      |> subscribe_and_join(MatchChannel, "matches:tournament:#{tournament_id}")

    {:ok, _, match_socket} =
      UserSocket
      |> socket("user-2", %{})
      |> subscribe_and_join(MatchChannel, "matches:match:#{match_id}")

    assert {:ok, _updated} = Matches.transition_match(match_id, :prepare, :admin)

    assert_push "match_transitioned", %{
      match_id: ^match_id,
      tournament_id: ^tournament_id,
      event: "prepare",
      to_state: "ready"
    }

    assert_receive %Phoenix.Socket.Broadcast{
      event: "match_transitioned",
      payload: %{
        match_id: ^match_id,
        tournament_id: ^tournament_id
      }
    }

    assert tournament_socket.topic == "matches:tournament:#{tournament_id}"
    assert match_socket.topic == "matches:match:#{match_id}"
  end

  test "receives score realtime event on tournament topic" do
    match = match_fixture(%{"state" => "ongoing"})
    match_id = match.id

    {:ok, _, _socket} =
      UserSocket
      |> socket("user-3", %{})
      |> subscribe_and_join(MatchChannel, "matches:tournament:#{match.tournament_id}")

    assert {:ok, _score_event} = Matches.record_score_event(match_id, :ippon, :aka, :men, :admin)

    assert_push "score_recorded", %{
      match_id: ^match_id,
      score_type: "ippon",
      side: "aka",
      target: "men"
    }
  end

  test "receives timer realtime event on match topic" do
    match = match_fixture(%{"state" => "ongoing"})
    match_id = match.id

    {:ok, _, _socket} =
      UserSocket
      |> socket("user-4", %{})
      |> subscribe_and_join(MatchChannel, "matches:match:#{match_id}")

    t0 = ~U[2026-04-23 14:00:00Z]
    t1 = ~U[2026-04-23 14:00:30Z]

    assert {:ok, _timer} = Matches.start_timer(match_id, :timekeeper, t0)
    assert_push "timer_updated", %{command: "start", to_status: "running", elapsed_ms: 0}

    assert {:ok, _timer} = Matches.pause_timer(match_id, :timekeeper, t1)

    assert_push "timer_updated", %{
      command: "pause",
      to_status: "paused",
      elapsed_ms: 30_000
    }
  end
end
