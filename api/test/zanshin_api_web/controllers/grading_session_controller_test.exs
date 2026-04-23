defmodule ZanshinApiWeb.GradingSessionControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.CompetitionsFixtures

  test "GET /api/v1/gradings/sessions requires tournament_id query param", %{conn: conn} do
    conn = get(conn, "/api/v1/gradings/sessions")
    assert %{"error" => "tournament_id_required"} = json_response(conn, 400)
  end

  test "GET /api/v1/gradings/sessions lists sessions by tournament_id", %{conn: conn} do
    tournament = tournament_fixture()
    _other_tournament = tournament_fixture(%{"name" => "Another Open"})

    {:ok, _session} =
      ZanshinApi.Gradings.create_session(%{
        "tournament_id" => tournament.id,
        "name" => "Spring Shinsa",
        "written_required" => true
      })

    conn = get(conn, "/api/v1/gradings/sessions?tournament_id=#{tournament.id}")
    assert %{"data" => [row], "pagination" => pagination} = json_response(conn, 200)
    assert row["tournament_id"] == tournament.id
    assert row["name"] == "Spring Shinsa"
    assert pagination["count"] == 1
  end
end
