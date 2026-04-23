defmodule ZanshinApi.AnalyticsTest do
  use ZanshinApi.DataCase, async: false

  alias ZanshinApi.Analytics
  alias ZanshinApi.Events

  defmodule Neo4jQueryClientSuccess do
    @behaviour ZanshinApi.Analytics.Neo4jClient

    @impl true
    def execute(_cypher, _params, _opts), do: :ok

    @impl true
    def query(cypher, _params, _opts) do
      if String.contains?(cypher, "total_events") do
        {:ok, [%{"total_events" => 3, "transition_events" => 2, "score_events" => 1}]}
      else
        {:ok,
         [
           %{"event_type" => "match.score_recorded", "count" => 1},
           %{"event_type" => "match.transitioned", "count" => 2}
         ]}
      end
    end
  end

  defmodule Neo4jQueryClientFailure do
    @behaviour ZanshinApi.Analytics.Neo4jClient

    @impl true
    def execute(_cypher, _params, _opts), do: :ok

    @impl true
    def query(_cypher, _params, _opts), do: {:error, :simulated_neo4j_unavailable}
  end

  setup do
    previous_source = Application.get_env(:zanshin_api, :analytics_summary_source)
    previous_client = Application.get_env(:zanshin_api, :neo4j_client)

    on_exit(fn ->
      Application.put_env(:zanshin_api, :analytics_summary_source, previous_source || :postgres)

      Application.put_env(
        :zanshin_api,
        :neo4j_client,
        previous_client || ZanshinApi.Analytics.Neo4jClient.Noop
      )
    end)

    :ok
  end

  test "match_summary/1 reads from neo4j when configured" do
    Application.put_env(:zanshin_api, :analytics_summary_source, :neo4j)
    Application.put_env(:zanshin_api, :neo4j_client, Neo4jQueryClientSuccess)

    tournament_id = Ecto.UUID.generate()

    assert {:ok, summary} =
             Analytics.match_summary(%{
               "tournament_id" => tournament_id,
               "limit" => "25",
               "offset" => "0"
             })

    assert summary.data_source == "neo4j"
    assert summary.kpis.total_events == 3
    assert summary.kpis.transition_events == 2
    assert summary.kpis.score_events == 1
    assert summary.kpis.processed_events == 3
    assert summary.kpis.unprocessed_events == 0
  end

  test "match_summary/1 falls back to postgres when neo4j read fails" do
    Application.put_env(:zanshin_api, :analytics_summary_source, :neo4j)
    Application.put_env(:zanshin_api, :neo4j_client, Neo4jQueryClientFailure)

    tournament_id = Ecto.UUID.generate()
    division_id = Ecto.UUID.generate()
    match_id = Ecto.UUID.generate()

    assert {:ok, processed_event} =
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

    assert {:ok, _} = Events.mark_processed(processed_event.id)

    assert {:ok, _score_event} =
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

    assert {:ok, summary} = Analytics.match_summary(%{"tournament_id" => tournament_id})

    assert summary.data_source == "postgres_fallback"
    assert summary.kpis.total_events == 2
    assert summary.kpis.processed_events == 1
    assert summary.kpis.unprocessed_events == 1
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
