defmodule ZanshinApiWeb.MatchControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.AuthHelpers
  import ZanshinApi.CompetitionsFixtures
  import ZanshinApi.MatchesFixtures

  test "POST /api/v1/matches creates a match for admin role", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/matches", valid_match_attrs())

    assert %{"data" => %{"id" => id, "state" => "scheduled"}} = json_response(conn, 201)
    assert is_binary(id)
  end

  test "POST /api/v1/matches rejects unauthorized role", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("shinpan"))
      |> post("/api/v1/matches", valid_match_attrs())

    assert %{"error" => "forbidden"} = json_response(conn, 403)
  end

  test "POST /api/v1/matches requires auth", %{conn: conn} do
    conn = post(conn, "/api/v1/matches", valid_match_attrs())
    assert %{"error" => "unauthorized"} = json_response(conn, 401)
  end

  test "GET /api/v1/matches/:id returns persisted match", %{conn: conn} do
    match = match_fixture()
    conn = get(conn, "/api/v1/matches/#{match.id}")

    assert %{"data" => %{"id" => id, "state" => "scheduled"}} = json_response(conn, 200)
    assert id == match.id
  end

  test "POST /api/v1/matches rejects mismatched tournament and division", %{conn: conn} do
    tournament = tournament_fixture(%{"name" => "Scoped Tournament"})
    other_tournament = tournament_fixture(%{"name" => "Other Tournament"})
    division = division_fixture(other_tournament)
    aka = competitor_fixture()
    shiro = competitor_fixture()

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/matches", %{
        "tournament_id" => tournament.id,
        "division_id" => division.id,
        "aka_competitor_id" => aka.id,
        "shiro_competitor_id" => shiro.id
      })

    assert %{"error" => "division_not_in_tournament"} = json_response(conn, 422)
  end
end
