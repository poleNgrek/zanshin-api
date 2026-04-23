defmodule ZanshinApiWeb.AnalyticsMatchSummaryControllerTest do
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

  test "GET /api/v1/analytics/matches/summary requires auth", %{conn: conn} do
    conn = get(conn, "/api/v1/analytics/matches/summary?tournament_id=tournament-1")
    assert %{"error" => "unauthorized"} = json_response(conn, 401)
  end

  test "GET /api/v1/analytics/matches/summary returns scoped summary data", %{conn: conn} do
    tournament_id = Ecto.UUID.generate()
    division_id = Ecto.UUID.generate()
    match_id = Ecto.UUID.generate()

    assert {:ok, processed_event} =
             create_domain_event(%{
               aggregate_id: match_id,
               event_type: "match.transitioned",
               payload: %{
                 "event" => "prepare",
                 "from_state" => "scheduled",
                 "to_state" => "ready",
                 "match_id" => match_id,
                 "tournament_id" => tournament_id,
                 "division_id" => division_id
               }
             })

    assert {:ok, _processed_record} = Events.mark_processed(processed_event.id)

    assert {:ok, _score_event} =
             create_domain_event(%{
               aggregate_id: match_id,
               event_type: "match.score_recorded",
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

    # Different tournament to verify filter scope.
    assert {:ok, _ignored_event} =
             create_domain_event(%{
               aggregate_id: Ecto.UUID.generate(),
               event_type: "match.transitioned",
               payload: %{
                 "event" => "prepare",
                 "from_state" => "scheduled",
                 "to_state" => "ready",
                 "match_id" => Ecto.UUID.generate(),
                 "tournament_id" => Ecto.UUID.generate(),
                 "division_id" => division_id
               }
             })

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> get(
        "/api/v1/analytics/matches/summary?tournament_id=#{tournament_id}&division_id=#{division_id}&limit=20&offset=0"
      )

    assert %{
             "data" => %{
               "scope" => %{
                 "tournament_id" => ^tournament_id,
                 "division_id" => ^division_id
               },
               "pagination" => %{"limit" => 20, "offset" => 0},
               "kpis" => %{
                 "total_events" => 2,
                 "processed_events" => 1,
                 "unprocessed_events" => 1,
                 "transition_events" => 1,
                 "score_events" => 1
               },
               "event_type_breakdown" => event_type_breakdown
             }
           } = json_response(conn, 200)

    assert Enum.any?(event_type_breakdown, fn row ->
             row["event_type"] == "match.transitioned" and row["count"] == 1
           end)

    assert Enum.any?(event_type_breakdown, fn row ->
             row["event_type"] == "match.score_recorded" and row["count"] == 1
           end)
  end

  test "GET /api/v1/analytics/matches/summary requires tournament_id", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> get("/api/v1/analytics/matches/summary")

    assert %{"error" => "tournament_id_required"} = json_response(conn, 400)
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
