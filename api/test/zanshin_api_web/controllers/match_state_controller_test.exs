defmodule ZanshinApiWeb.MatchStateControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.AuthHelpers
  import ZanshinApi.MatchesFixtures

  test "POST /api/v1/matches/:id/transition transitions a persisted match", %{conn: conn} do
    match = match_fixture()

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> put_req_header("idempotency-key", "match-transition-initial-1")
      |> post("/api/v1/matches/#{match.id}/transition", %{"event" => "prepare"})

    assert %{"data" => %{"id" => id, "new_state" => "ready"}} = json_response(conn, 200)
    assert id == match.id
  end

  test "POST /api/v1/matches/:id/transition rejects forbidden role transition", %{conn: conn} do
    match = match_fixture(%{"state" => "ongoing"})

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("shinpan"))
      |> put_req_header("idempotency-key", "match-transition-forbidden-1")
      |> post("/api/v1/matches/#{match.id}/transition", %{"event" => "complete"})

    assert %{"error" => "forbidden_transition_for_role"} = json_response(conn, 403)
  end

  test "POST /api/v1/matches/:id/transition requires JWT auth", %{conn: conn} do
    match = match_fixture()
    conn = post(conn, "/api/v1/matches/#{match.id}/transition", %{"event" => "prepare"})

    assert %{"error" => "unauthorized"} = json_response(conn, 401)
  end

  test "POST /api/v1/matches/:id/transition replays response for same idempotency key", %{
    conn: conn
  } do
    match = match_fixture()

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> put_req_header("idempotency-key", "match-transition-idem-key-1")
      |> post("/api/v1/matches/#{match.id}/transition", %{"event" => "prepare"})

    assert %{"data" => %{"id" => first_id, "new_state" => "ready"}} = json_response(conn, 200)
    assert first_id == match.id

    replay_conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> put_req_header("idempotency-key", "match-transition-idem-key-1")
      |> post("/api/v1/matches/#{match.id}/transition", %{"event" => "prepare"})

    assert get_resp_header(replay_conn, "x-idempotent-replayed") == ["true"]

    assert %{"data" => %{"id" => replay_id, "new_state" => "ready"}} =
             json_response(replay_conn, 200)

    assert replay_id == match.id
  end

  test "POST /api/v1/matches/:id/transition rejects missing idempotency key", %{conn: conn} do
    match = match_fixture()

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/matches/#{match.id}/transition", %{"event" => "prepare"})

    assert %{"error" => "idempotency_key_required"} = json_response(conn, 400)
  end

  test "POST /api/v1/matches/:id/transition rejects key reuse for different payload", %{
    conn: conn
  } do
    match = match_fixture()

    _conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> put_req_header("idempotency-key", "match-transition-idem-key-2")
      |> post("/api/v1/matches/#{match.id}/transition", %{"event" => "prepare"})

    conflict_conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> put_req_header("idempotency-key", "match-transition-idem-key-2")
      |> post("/api/v1/matches/#{match.id}/transition", %{"event" => "start"})

    assert %{"error" => "idempotency_key_reused_with_different_payload"} =
             json_response(conflict_conn, 409)
  end
end
