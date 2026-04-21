defmodule ZanshinApiWeb.MatchScoreControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.AuthHelpers
  import ZanshinApi.CompetitionsFixtures
  import ZanshinApi.MatchesFixtures
  alias ZanshinApi.Competitions

  test "POST /api/v1/matches/:id/score records score for ongoing match", %{conn: conn} do
    match = match_fixture(%{"state" => "ongoing"})

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("shinpan"))
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
      |> post("/api/v1/matches/#{match.id}/score", %{"score_type" => "hansoku", "side" => "shiro"})

    assert %{"error" => "match_not_ongoing"} = json_response(conn, 422)
  end

  test "POST /api/v1/matches/:id/score rejects forbidden role", %{conn: conn} do
    match = match_fixture(%{"state" => "ongoing"})

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("timekeeper"))
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
      |> post("/api/v1/matches/#{match.id}/score", %{
        "score_type" => "ippon",
        "side" => "aka",
        "target" => "tsuki"
      })

    assert %{"error" => "tsuki_not_allowed"} = json_response(conn, 422)
  end
end
