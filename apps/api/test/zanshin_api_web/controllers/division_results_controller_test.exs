defmodule ZanshinApiWeb.DivisionResultsControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.AuthHelpers
  import ZanshinApi.CompetitionsFixtures

  test "POST /api/v1/division_medal_results enforces two bronze winners only", %{conn: conn} do
    tournament = tournament_fixture()
    division = division_fixture(tournament)
    c1 = competitor_fixture()
    c2 = competitor_fixture()
    c3 = competitor_fixture()

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/division_medal_results", %{
        "division_id" => division.id,
        "place" => 3,
        "competitor_id" => c1.id
      })

    assert %{"data" => %{"medal" => "bronze", "place" => 3}} = json_response(conn, 201)

    conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/division_medal_results", %{
        "division_id" => division.id,
        "place" => 3,
        "competitor_id" => c2.id
      })

    assert %{"data" => %{"medal" => "bronze", "place" => 3}} = json_response(conn, 201)

    conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/division_medal_results", %{
        "division_id" => division.id,
        "place" => 3,
        "competitor_id" => c3.id
      })

    assert %{"error" => "place_capacity_reached"} = json_response(conn, 422)
  end

  test "POST /api/v1/division_special_awards creates fighting spirit award", %{conn: conn} do
    tournament = tournament_fixture()
    division = division_fixture(tournament)
    competitor = competitor_fixture()

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/division_special_awards", %{
        "division_id" => division.id,
        "award_type" => "fighting_spirit",
        "competitor_id" => competitor.id
      })

    assert %{"data" => %{"award_type" => "fighting_spirit", "competitor_id" => id}} =
             json_response(conn, 201)

    assert id == competitor.id
  end
end
