defmodule ZanshinApiWeb.MatchControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.AuthHelpers
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
end
