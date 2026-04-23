defmodule ZanshinApiWeb.ApiDocsControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  test "serves swagger docs html", %{conn: conn} do
    conn = get(conn, "/api/docs")
    body = html_response(conn, 200)
    assert body =~ "swagger-ui"
    assert body =~ "/openapi.yaml"
  end

  test "serves openapi static document", %{conn: conn} do
    conn = get(conn, "/openapi.yaml")
    assert response(conn, 200) =~ "openapi: 3.0.3"
  end
end
