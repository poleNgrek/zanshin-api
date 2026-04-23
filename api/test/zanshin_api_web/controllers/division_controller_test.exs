defmodule ZanshinApiWeb.DivisionControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.CompetitionsFixtures

  test "GET /api/v1/divisions requires tournament_id query param", %{conn: conn} do
    conn = get(conn, "/api/v1/divisions")
    assert %{"error" => "tournament_id_required"} = json_response(conn, 400)
  end

  test "GET /api/v1/divisions lists divisions for tournament_id", %{conn: conn} do
    tournament = tournament_fixture()
    _division = division_fixture(tournament, %{"name" => "Adults"})

    conn = get(conn, "/api/v1/divisions?tournament_id=#{tournament.id}")
    assert %{"data" => [row]} = json_response(conn, 200)
    assert row["tournament_id"] == tournament.id
    assert row["name"] == "Adults"
  end
end
