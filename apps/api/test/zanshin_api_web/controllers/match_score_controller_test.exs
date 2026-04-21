defmodule ZanshinApiWeb.MatchScoreControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.AuthHelpers
  import ZanshinApi.MatchesFixtures

  test "POST /api/v1/matches/:id/score records score for ongoing match", %{conn: conn} do
    match = match_fixture(%{"state" => "ongoing"})

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("shinpan"))
      |> post("/api/v1/matches/#{match.id}/score", %{"score_type" => "ippon", "side" => "aka"})

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
      |> post("/api/v1/matches/#{match.id}/score", %{"score_type" => "ippon", "side" => "aka"})

    assert %{"error" => "forbidden_score_for_role"} = json_response(conn, 403)
  end
end
