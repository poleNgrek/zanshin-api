defmodule ZanshinApiWeb.MatchStateControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.MatchesFixtures

  test "POST /api/v1/matches/:id/transition transitions a persisted match", %{conn: conn} do
    match = match_fixture()

    conn =
      conn
      |> put_req_header("x-actor-role", "admin")
      |> post("/api/v1/matches/#{match.id}/transition", %{"event" => "prepare"})

    assert %{"data" => %{"id" => id, "new_state" => "ready"}} = json_response(conn, 200)
    assert id == match.id
  end

  test "POST /api/v1/matches/:id/transition rejects forbidden role transition", %{conn: conn} do
    match = match_fixture(%{"state" => "ongoing"})

    conn =
      conn
      |> put_req_header("x-actor-role", "shinpan")
      |> post("/api/v1/matches/#{match.id}/transition", %{"event" => "complete"})

    assert %{"error" => "forbidden_transition_for_role"} = json_response(conn, 403)
  end
end
