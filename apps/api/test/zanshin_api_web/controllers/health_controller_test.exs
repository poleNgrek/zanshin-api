defmodule ZanshinApiWeb.HealthControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  test "GET /api/v1/health returns service status", %{conn: conn} do
    conn = get(conn, "/api/v1/health")

    assert %{"status" => "ok", "service" => "zanshin_api"} = json_response(conn, 200)
  end
end
