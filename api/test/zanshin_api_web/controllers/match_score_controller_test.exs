defmodule ZanshinApiWeb.MatchScoreControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.AuthHelpers
  import ZanshinApi.CompetitionsFixtures
  import ZanshinApi.MatchesFixtures
  alias ZanshinApi.Competitions
  alias ZanshinApi.Matches

  test "POST /api/v1/matches/:id/score records score for ongoing match", %{conn: conn} do
    match = match_fixture(%{"state" => "ongoing"})

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("shinpan"))
      |> put_req_header("idempotency-key", "match-score-valid-1")
      |> post("/api/v1/matches/#{match.id}/score", %{
        "score_type" => "ippon",
        "side" => "aka",
        "target" => "men"
      })

    assert %{"data" => %{"score_type" => "ippon", "side" => "aka"}} = json_response(conn, 201)
  end

  test "POST /api/v1/matches/:id/score rejects score when match is not ongoing", %{conn: conn} do
    match = match_fixture(%{"state" => "ready"})

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("shinpan"))
      |> put_req_header("idempotency-key", "match-score-not-ongoing-1")
      |> post("/api/v1/matches/#{match.id}/score", %{"score_type" => "hansoku", "side" => "shiro"})

    assert %{"error" => "match_not_ongoing"} = json_response(conn, 422)
  end

  test "POST /api/v1/matches/:id/score rejects forbidden role", %{conn: conn} do
    match = match_fixture(%{"state" => "ongoing"})

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("timekeeper"))
      |> put_req_header("idempotency-key", "match-score-forbidden-1")
      |> post("/api/v1/matches/#{match.id}/score", %{
        "score_type" => "ippon",
        "side" => "aka",
        "target" => "men"
      })

    assert %{"error" => "forbidden_score_for_role"} = json_response(conn, 403)
  end

  test "POST /api/v1/matches/:id/score rejects tsuki when disallowed by rules", %{conn: conn} do
    match = match_fixture(%{"state" => "ongoing"})
    division = Competitions.list_divisions_by_tournament(match.tournament_id) |> List.first()
    _rules = division_rule_fixture(division, %{"allow_tsuki" => false, "age_group" => "children"})

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("shinpan"))
      |> put_req_header("idempotency-key", "match-score-tsuki-1")
      |> post("/api/v1/matches/#{match.id}/score", %{
        "score_type" => "ippon",
        "side" => "aka",
        "target" => "tsuki"
      })

    assert %{"error" => "tsuki_not_allowed"} = json_response(conn, 422)
  end

  test "POST /api/v1/matches/:id/score replays response for same idempotency key", %{conn: conn} do
    match = match_fixture(%{"state" => "ongoing"})

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("shinpan"))
      |> put_req_header("idempotency-key", "match-score-idem-key-1")
      |> post("/api/v1/matches/#{match.id}/score", %{
        "score_type" => "ippon",
        "side" => "aka",
        "target" => "men"
      })

    assert %{"data" => %{"id" => first_score_id, "score_type" => "ippon", "side" => "aka"}} =
             json_response(conn, 201)

    replay_conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("shinpan"))
      |> put_req_header("idempotency-key", "match-score-idem-key-1")
      |> post("/api/v1/matches/#{match.id}/score", %{
        "score_type" => "ippon",
        "side" => "aka",
        "target" => "men"
      })

    assert get_resp_header(replay_conn, "x-idempotent-replayed") == ["true"]

    assert %{"data" => %{"id" => replay_score_id, "score_type" => "ippon", "side" => "aka"}} =
             json_response(replay_conn, 201)

    assert replay_score_id == first_score_id
    assert length(Matches.list_score_events(match.id)) == 1
  end

  test "GET /api/v1/matches/:id/score supports pagination metadata", %{conn: conn} do
    match = match_fixture(%{"state" => "ongoing"})

    _first_conn =
      conn
      |> put_req_header("authorization", bearer_token_for("shinpan"))
      |> put_req_header("idempotency-key", "match-score-list-1")
      |> post("/api/v1/matches/#{match.id}/score", %{
        "score_type" => "ippon",
        "side" => "aka",
        "target" => "men"
      })

    _second_conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("shinpan"))
      |> put_req_header("idempotency-key", "match-score-list-2")
      |> post("/api/v1/matches/#{match.id}/score", %{
        "score_type" => "ippon",
        "side" => "shiro",
        "target" => "do"
      })

    list_conn = get(build_conn(), "/api/v1/matches/#{match.id}/score?limit=1&offset=1")

    assert %{"data" => [row], "pagination" => pagination} = json_response(list_conn, 200)
    assert row["side"] == "shiro"
    assert pagination["limit"] == 1
    assert pagination["offset"] == 1
    assert pagination["count"] == 1
  end
end
