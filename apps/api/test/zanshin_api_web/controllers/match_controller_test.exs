defmodule ZanshinApiWeb.MatchControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.MatchesFixtures

  test "POST /api/v1/matches creates a match", %{conn: conn} do
    conn = post(conn, "/api/v1/matches", valid_match_attrs())

    assert %{"data" => %{"id" => id, "state" => "scheduled"}} = json_response(conn, 201)
    assert is_binary(id)
  end

  test "GET /api/v1/matches/:id returns persisted match", %{conn: conn} do
    match = match_fixture()
    conn = get(conn, "/api/v1/matches/#{match.id}")

    assert %{"data" => %{"id" => id, "state" => "scheduled"}} = json_response(conn, 200)
    assert id == match.id
  end
end
