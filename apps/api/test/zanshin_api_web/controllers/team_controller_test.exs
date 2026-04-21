defmodule ZanshinApiWeb.TeamControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.AuthHelpers
  import ZanshinApi.CompetitionsFixtures

  test "POST /api/v1/teams creates team and member with taisho position", %{conn: conn} do
    tournament = tournament_fixture()
    division = division_fixture(tournament, %{"format" => "team"})
    competitor = competitor_fixture()

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/teams", %{"division_id" => division.id, "name" => "Budokan"})

    assert %{"data" => %{"id" => team_id}} = json_response(conn, 201)

    conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/teams/#{team_id}/members", %{
        "competitor_id" => competitor.id,
        "position" => "taisho"
      })

    assert %{"data" => %{"position" => "taisho"}} = json_response(conn, 201)
  end
end
