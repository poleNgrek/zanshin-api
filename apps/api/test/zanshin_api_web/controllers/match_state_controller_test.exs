defmodule ZanshinApiWeb.MatchStateControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  test "POST /api/v1/matches/transition returns next state for valid transition", %{conn: conn} do
    conn =
      post(conn, "/api/v1/matches/transition", %{
        "current_state" => "scheduled",
        "event" => "prepare"
      })

    assert %{"current_state" => "scheduled", "new_state" => "ready"} = json_response(conn, 200)
  end

  test "POST /api/v1/matches/transition rejects invalid transition", %{conn: conn} do
    conn =
      post(conn, "/api/v1/matches/transition", %{
        "current_state" => "scheduled",
        "event" => "verify"
      })

    assert %{"error" => "invalid_transition"} = json_response(conn, 422)
  end
end
