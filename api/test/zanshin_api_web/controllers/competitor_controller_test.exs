defmodule ZanshinApiWeb.CompetitorControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.AuthHelpers

  test "POST /api/v1/competitors stores stance and grade profile", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/competitors", %{
        "display_name" => "Examinee One",
        "photo_url" => "https://cdn.example.com/examinee.png",
        "preferred_stance" => "jodan_right",
        "grade_type" => "dan",
        "grade_value" => 6,
        "grade_title" => "renshi"
      })

    assert %{
             "data" => %{
               "display_name" => "Examinee One",
               "avatar_url" => "https://cdn.example.com/examinee.png",
               "preferred_stance" => "jodan_right",
               "grade_type" => "dan",
               "grade_value" => 6,
               "grade_title" => "renshi"
             }
           } = json_response(conn, 201)
  end
end
