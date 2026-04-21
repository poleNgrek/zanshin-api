defmodule ZanshinApiWeb.DivisionRuleControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.AuthHelpers
  import ZanshinApi.CompetitionsFixtures

  test "PUT /api/v1/divisions/:id/rules upserts rule set", %{conn: conn} do
    tournament = tournament_fixture()
    division = division_fixture(tournament)

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> put("/api/v1/divisions/#{division.id}/rules", %{
        "category_type" => "mixed",
        "age_group" => "children",
        "min_age" => 8,
        "max_age" => 13,
        "match_duration_seconds" => 180,
        "allow_tsuki" => false
      })

    assert %{"data" => %{"category_type" => "mixed", "allow_tsuki" => false}} =
             json_response(conn, 200)
  end
end
