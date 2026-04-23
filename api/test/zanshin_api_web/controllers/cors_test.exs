defmodule ZanshinApiWeb.CorsTest do
  use ZanshinApiWeb.ConnCase, async: true

  test "adds CORS headers for allowed origin", %{conn: conn} do
    conn =
      conn
      |> put_req_header("origin", "http://127.0.0.1:3000")
      |> get("/api/v1/health")

    assert get_resp_header(conn, "access-control-allow-origin") == ["http://127.0.0.1:3000"]
    assert get_resp_header(conn, "access-control-allow-methods") != []
    assert get_resp_header(conn, "access-control-allow-headers") != []
  end

  test "handles CORS preflight with no-content response", %{conn: conn} do
    conn =
      conn
      |> put_req_header("origin", "http://localhost:3000")
      |> put_req_header("access-control-request-method", "GET")
      |> options("/api/v1/health")

    assert response(conn, 204)
    assert get_resp_header(conn, "access-control-allow-origin") == ["http://localhost:3000"]
  end

  test "accepts localhost origins on arbitrary dev ports", %{conn: conn} do
    conn =
      conn
      |> put_req_header("origin", "http://localhost:53033")
      |> get("/api/v1/health")

    assert get_resp_header(conn, "access-control-allow-origin") == ["http://localhost:53033"]
  end
end
