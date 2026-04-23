defmodule ZanshinApiWeb.RealtimeEventsControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.AuthHelpers
  import ZanshinApi.MatchesFixtures

  alias ZanshinApi.Matches

  test "GET /api/v1/realtime/matches/stream emits SSE snapshot for admin", %{conn: conn} do
    match = match_fixture(%{"state" => "ongoing"})

    assert {:ok, _} = Matches.record_score_event(match.id, :ippon, :aka, :men, :admin)

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> get("/api/v1/realtime/matches/stream?tournament_id=#{match.tournament_id}")

    assert conn.status == 200
    assert get_resp_header(conn, "content-type") |> List.first() =~ "text/event-stream"
    assert conn.resp_body =~ "event: match_events_snapshot"
    assert conn.resp_body =~ "match.score_recorded"
  end

  test "GET /api/v1/realtime/matches/stream requires tournament_id", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> get("/api/v1/realtime/matches/stream")

    assert %{"error" => "tournament_id_required"} = json_response(conn, 400)
  end

  test "GET /api/v1/realtime/matches/stream forbids non-admin", %{conn: conn} do
    match = match_fixture(%{"state" => "ongoing"})

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("timekeeper"))
      |> get("/api/v1/realtime/matches/stream?tournament_id=#{match.tournament_id}")

    assert %{"error" => "forbidden"} = json_response(conn, 403)
  end
end
