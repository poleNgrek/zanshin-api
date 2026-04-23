defmodule ZanshinApiWeb.DivisionStageControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.AuthHelpers
  import ZanshinApi.CompetitionsFixtures

  test "POST /api/v1/division_stages creates stage for division progression", %{conn: conn} do
    tournament = tournament_fixture()
    division = division_fixture(tournament, %{"format" => "hybrid"})

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/division_stages", %{
        "division_id" => division.id,
        "stage_type" => "pool_to_knockout",
        "sequence" => 1,
        "advances_count" => 2
      })

    assert %{"data" => %{"stage_type" => "pool_to_knockout", "sequence" => 1}} =
             json_response(conn, 201)
  end

  test "GET /api/v1/division_stages lists stages publicly by division", %{conn: conn} do
    tournament = tournament_fixture()
    division = division_fixture(tournament, %{"format" => "hybrid"})
    _s1 = division_stage_fixture(division, %{"stage_type" => "round_robin", "sequence" => 1})
    _s2 = division_stage_fixture(division, %{"stage_type" => "knockout", "sequence" => 2})

    conn = get(conn, "/api/v1/division_stages?division_id=#{division.id}")
    assert %{"data" => [first, second]} = json_response(conn, 200)
    assert first["stage_type"] == "round_robin"
    assert second["stage_type"] == "knockout"
  end

  test "GET /api/v1/division_stages requires division_id query param", %{conn: conn} do
    conn = get(conn, "/api/v1/division_stages")
    assert %{"error" => "division_id_required"} = json_response(conn, 400)
  end
end
