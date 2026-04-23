defmodule ZanshinApiWeb.DivisionResultsControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.AuthHelpers
  import ZanshinApi.CompetitionsFixtures
  alias ZanshinApi.Matches.Match
  alias ZanshinApi.Matches.ScoreEvent
  alias ZanshinApi.Matches
  alias ZanshinApi.Repo

  test "POST /api/v1/division_medal_results enforces two bronze winners only", %{conn: conn} do
    tournament = tournament_fixture()
    division = division_fixture(tournament)
    c1 = competitor_fixture()
    c2 = competitor_fixture()
    c3 = competitor_fixture()

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/division_medal_results", %{
        "division_id" => division.id,
        "place" => 3,
        "competitor_id" => c1.id
      })

    assert %{"data" => %{"medal" => "bronze", "place" => 3}} = json_response(conn, 201)

    conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/division_medal_results", %{
        "division_id" => division.id,
        "place" => 3,
        "competitor_id" => c2.id
      })

    assert %{"data" => %{"medal" => "bronze", "place" => 3}} = json_response(conn, 201)

    conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/division_medal_results", %{
        "division_id" => division.id,
        "place" => 3,
        "competitor_id" => c3.id
      })

    assert %{"error" => "place_capacity_reached"} = json_response(conn, 422)
  end

  test "POST /api/v1/division_special_awards creates fighting spirit award", %{conn: conn} do
    tournament = tournament_fixture()
    division = division_fixture(tournament)
    competitor = competitor_fixture()

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/division_special_awards", %{
        "division_id" => division.id,
        "award_type" => "fighting_spirit",
        "competitor_id" => competitor.id
      })

    assert %{"data" => %{"award_type" => "fighting_spirit", "competitor_id" => id}} =
             json_response(conn, 201)

    assert id == competitor.id
  end

  test "POST /api/v1/divisions/:id/compute_results computes podium from bracket results", %{
    conn: conn
  } do
    tournament = tournament_fixture()
    division = division_fixture(tournament, %{"format" => "bracket"})
    c1 = competitor_fixture()
    c2 = competitor_fixture()
    c3 = competitor_fixture()
    c4 = competitor_fixture()

    _semi_1 = completed_match_fixture(tournament, division, c1, c2, 2, 0)
    _semi_2 = completed_match_fixture(tournament, division, c3, c4, 2, 1)
    _final = completed_match_fixture(tournament, division, c1, c3, 2, 1)

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/divisions/#{division.id}/compute_results", %{})

    assert %{"data" => results} = json_response(conn, 200)
    assert length(results) == 4
    assert Enum.count(results, fn r -> r["medal"] == "bronze" end) == 2
    assert Enum.any?(results, fn r -> r["medal"] == "gold" and r["competitor_id"] == c1.id end)
    assert Enum.any?(results, fn r -> r["medal"] == "silver" and r["competitor_id"] == c3.id end)
  end

  defp completed_match_fixture(tournament, division, aka, shiro, aka_points, shiro_points) do
    {:ok, match} =
      Matches.create_match(%{
        "tournament_id" => tournament.id,
        "division_id" => division.id,
        "aka_competitor_id" => aka.id,
        "shiro_competitor_id" => shiro.id
      })

    {:ok, completed} = match |> Match.transition_changeset(%{state: :completed}) |> Repo.update()

    if aka_points > 0 do
      Enum.each(1..aka_points, fn _ ->
        %ScoreEvent{}
        |> ScoreEvent.changeset(%{
          "match_id" => completed.id,
          "score_type" => "ippon",
          "side" => "aka",
          "target" => "men",
          "actor_role" => "admin"
        })
        |> Repo.insert!()
      end)
    end

    if shiro_points > 0 do
      Enum.each(1..shiro_points, fn _ ->
        %ScoreEvent{}
        |> ScoreEvent.changeset(%{
          "match_id" => completed.id,
          "score_type" => "ippon",
          "side" => "shiro",
          "target" => "men",
          "actor_role" => "admin"
        })
        |> Repo.insert!()
      end)
    end

    completed
  end
end
