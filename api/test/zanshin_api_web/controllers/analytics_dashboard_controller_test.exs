defmodule ZanshinApiWeb.AnalyticsDashboardControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.AuthHelpers

  alias ZanshinApi.Events

  setup do
    :ok = ZanshinApi.TestOAuth.setup!()

    previous_source = Application.get_env(:zanshin_api, :analytics_summary_source)
    Application.put_env(:zanshin_api, :analytics_summary_source, :postgres)

    on_exit(fn ->
      Application.put_env(:zanshin_api, :analytics_summary_source, previous_source || :neo4j)
    end)

    :ok
  end

  test "GET /api/v1/analytics/events/feed returns scoped event list", %{conn: conn} do
    tournament_id = Ecto.UUID.generate()
    division_id = Ecto.UUID.generate()
    match_id = Ecto.UUID.generate()

    {:ok, _transition_event} =
      create_domain_event(%{
        event_type: "match.transitioned",
        aggregate_id: match_id,
        payload: %{
          "event" => "prepare",
          "from_state" => "scheduled",
          "to_state" => "ready",
          "match_id" => match_id,
          "tournament_id" => tournament_id,
          "division_id" => division_id
        }
      })

    {:ok, _score_event} =
      create_domain_event(%{
        event_type: "match.score_recorded",
        aggregate_id: match_id,
        payload: %{
          "score_event_id" => Ecto.UUID.generate(),
          "score_type" => "ippon",
          "side" => "aka",
          "target" => "men",
          "match_id" => match_id,
          "tournament_id" => tournament_id,
          "division_id" => division_id
        }
      })

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> get(
        "/api/v1/analytics/events/feed?tournament_id=#{tournament_id}&division_id=#{division_id}&limit=10"
      )

    response_payload = json_response(conn, 200)

    assert %{
             "data" => %{
               "data_source" => data_source,
               "events" => events,
               "pagination" => %{"limit" => 10, "offset" => 0}
             }
           } = response_payload

    assert data_source in ["postgres", "postgres_fallback"]

    assert length(events) == 2
    assert Enum.any?(events, &(&1["event_type"] == "match.transitioned"))
    assert Enum.any?(events, &(&1["event_type"] == "match.score_recorded"))
  end

  test "GET /api/v1/analytics/matches/state_overview returns grouped states", %{conn: conn} do
    tournament_id = Ecto.UUID.generate()
    division_id = Ecto.UUID.generate()

    {:ok, _first_match} =
      create_domain_event(%{
        event_type: "match.transitioned",
        aggregate_id: Ecto.UUID.generate(),
        payload: %{
          "event" => "prepare",
          "from_state" => "scheduled",
          "to_state" => "ready",
          "match_id" => Ecto.UUID.generate(),
          "tournament_id" => tournament_id,
          "division_id" => division_id
        }
      })

    {:ok, _second_match} =
      create_domain_event(%{
        event_type: "match.transitioned",
        aggregate_id: Ecto.UUID.generate(),
        payload: %{
          "event" => "start",
          "from_state" => "ready",
          "to_state" => "ongoing",
          "match_id" => Ecto.UUID.generate(),
          "tournament_id" => tournament_id,
          "division_id" => division_id
        }
      })

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> get(
        "/api/v1/analytics/matches/state_overview?tournament_id=#{tournament_id}&division_id=#{division_id}"
      )

    response_payload = json_response(conn, 200)

    assert %{
             "data" => %{
               "data_source" => data_source,
               "state_counts" => state_counts
             }
           } = response_payload

    assert data_source in ["postgres", "postgres_fallback"]

    assert Enum.any?(state_counts, fn row -> row["state"] == "ongoing" and row["count"] == 1 end)
    assert Enum.any?(state_counts, fn row -> row["state"] == "ready" and row["count"] == 1 end)
  end

  test "GET /api/v1/analytics/dashboard/overview returns consolidated payload", %{conn: conn} do
    tournament_id = Ecto.UUID.generate()
    division_id = Ecto.UUID.generate()

    {:ok, _transition_event} =
      create_domain_event(%{
        event_type: "match.transitioned",
        aggregate_id: Ecto.UUID.generate(),
        payload: %{
          "event" => "start",
          "from_state" => "ready",
          "to_state" => "ongoing",
          "match_id" => Ecto.UUID.generate(),
          "tournament_id" => tournament_id,
          "division_id" => division_id
        }
      })

    {:ok, _score_event} =
      create_domain_event(%{
        event_type: "match.score_recorded",
        aggregate_id: Ecto.UUID.generate(),
        payload: %{
          "score_event_id" => Ecto.UUID.generate(),
          "score_type" => "waza_ari",
          "side" => "shiro",
          "target" => "do",
          "match_id" => Ecto.UUID.generate(),
          "tournament_id" => tournament_id,
          "division_id" => division_id
        }
      })

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> get(
        "/api/v1/analytics/dashboard/overview?tournament_id=#{tournament_id}&division_id=#{division_id}"
      )

    response_payload = json_response(conn, 200)

    assert %{
             "data" => %{
               "data_source" => data_source,
               "summary" => %{
                 "kpis" => %{"total_events" => 2},
                 "event_type_breakdown" => breakdown
               },
               "state_overview" => %{"state_counts" => state_counts},
               "recent_events" => recent_events,
               "insights" => %{
                 "throughput_trend" => throughput_trend,
                 "top_active_matches" => top_active_matches,
                 "actor_role_activity" => actor_role_activity
               }
             }
           } = response_payload

    assert data_source in ["postgres", "postgres_fallback"]

    assert Enum.any?(breakdown, fn row ->
             row["event_type"] == "match.transitioned" and row["count"] == 1
           end)

    assert Enum.any?(state_counts, fn row -> row["state"] == "ongoing" and row["count"] == 1 end)
    assert length(recent_events) == 2
    assert Enum.any?(throughput_trend, fn row -> row["total_events"] >= 1 end)
    assert Enum.any?(top_active_matches, fn row -> row["event_count"] >= 1 end)
    assert Enum.any?(actor_role_activity, fn row -> row["actor_role"] == "admin" end)
  end

  test "analytics dashboard endpoints require auth", %{conn: conn} do
    feed_conn = get(conn, "/api/v1/analytics/events/feed?tournament_id=#{Ecto.UUID.generate()}")
    assert %{"error" => "unauthorized"} = json_response(feed_conn, 401)

    overview_conn =
      get(conn, "/api/v1/analytics/matches/state_overview?tournament_id=#{Ecto.UUID.generate()}")

    assert %{"error" => "unauthorized"} = json_response(overview_conn, 401)
  end

  defp create_domain_event(attrs) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    default_attrs = %{
      event_type: "match.transitioned",
      event_version: 1,
      aggregate_type: "match",
      aggregate_id: Ecto.UUID.generate(),
      occurred_at: now,
      actor_role: "admin",
      source: "test",
      payload: %{}
    }

    Events.create_domain_event(Map.merge(default_attrs, attrs))
  end
end
