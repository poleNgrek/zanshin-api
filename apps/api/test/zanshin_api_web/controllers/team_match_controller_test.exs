defmodule ZanshinApiWeb.TeamMatchControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.AuthHelpers
  import ZanshinApi.CompetitionsFixtures

  test "POST /api/v1/team_matches creates completed match with representative winner", %{
    conn: conn
  } do
    tournament = tournament_fixture()
    division = division_fixture(tournament, %{"format" => "team"})
    team_a = team_fixture(division)
    team_b = team_fixture(division)

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/team_matches", %{
        "division_id" => division.id,
        "team_a_id" => team_a.id,
        "team_b_id" => team_b.id,
        "state" => "completed",
        "team_a_wins" => 2,
        "team_b_wins" => 2,
        "representative_match_required" => true,
        "representative_winner_team_id" => team_a.id
      })

    assert %{"data" => %{"winner_team_id" => winner_id, "representative_match_required" => true}} =
             json_response(conn, 201)

    assert winner_id == team_a.id
  end
end
