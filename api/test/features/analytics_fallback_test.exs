defmodule ZanshinApi.Features.AnalyticsFallbackTest do
  use ZanshinApi.TestSupport.Cabbage.Feature,
    file: "analytics_fallback.feature",
    template: ZanshinApiWeb.ConnCase,
    async: false

  alias ZanshinApi.TestSupport.Cabbage.Helpers
  import_feature(ZanshinApi.TestSupport.Cabbage.AnalyticsSteps)

  setup %{conn: conn} do
    previous_source = Application.get_env(:zanshin_api, :analytics_summary_source)
    Application.put_env(:zanshin_api, :analytics_summary_source, :postgres)

    on_exit(fn ->
      Application.put_env(:zanshin_api, :analytics_summary_source, previous_source || :neo4j)
    end)

    {:ok, %{world: Helpers.new_world(conn)}}
  end
end
