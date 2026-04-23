defmodule ZanshinApiWeb.CompetitionControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.AuthHelpers
  import ZanshinApi.CompetitionsFixtures

  test "GET /api/v1/tournaments lists tournaments without auth", %{conn: conn} do
    t = tournament_fixture(%{"name" => "Public Cup"})
    conn = get(conn, "/api/v1/tournaments")

    assert %{"data" => tournaments, "pagination" => pagination} = json_response(conn, 200)
    assert Enum.any?(tournaments, fn row -> row["id"] == t.id end)
    assert pagination["offset"] == 0
    assert pagination["limit"] == 50
  end

  test "GET /api/v1/tournaments applies limit and offset", %{conn: conn} do
    _t1 = tournament_fixture(%{"name" => "Cup 1"})
    t2 = tournament_fixture(%{"name" => "Cup 2"})
    _t3 = tournament_fixture(%{"name" => "Cup 3"})

    conn = get(conn, "/api/v1/tournaments?limit=1&offset=1")

    assert %{"data" => [row], "pagination" => pagination} = json_response(conn, 200)
    assert row["id"] == t2.id
    assert pagination["limit"] == 1
    assert pagination["offset"] == 1
    assert pagination["count"] == 1
    assert pagination["total"] >= 3
  end

  test "GET /api/v1/tournaments rejects invalid pagination params", %{conn: conn} do
    conn = get(conn, "/api/v1/tournaments?limit=0")
    assert %{"error" => "invalid_pagination"} = json_response(conn, 400)
  end

  test "POST /api/v1/tournaments requires auth", %{conn: conn} do
    conn = post(conn, "/api/v1/tournaments", %{"name" => "Secured Cup"})
    assert %{"error" => "unauthorized"} = json_response(conn, 401)
  end

  test "POST /api/v1/tournaments allows admin", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/tournaments", %{"name" => "Secured Cup"})

    assert %{"data" => %{"name" => "Secured Cup"}} = json_response(conn, 201)
  end

  test "GET /api/v1/tournaments/:id/export returns tournament snapshot for admin", %{conn: conn} do
    tournament = tournament_fixture()
    division = division_fixture(tournament)
    _rules = division_rule_fixture(division)

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> get("/api/v1/tournaments/#{tournament.id}/export")

    assert %{
             "data" => %{
               "metadata" => %{"schema_version" => 1},
               "tournament" => %{"id" => id},
               "divisions" => divisions
             }
           } = json_response(conn, 200)

    assert id == tournament.id
    assert Enum.any?(divisions, fn d -> d["id"] == division.id end)
  end
end
