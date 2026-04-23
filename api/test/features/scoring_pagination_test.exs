defmodule ZanshinApi.Features.ScoringPaginationTest do
  use ZanshinApi.TestSupport.Cabbage.Feature,
    file: "scoring_pagination.feature",
    template: ZanshinApiWeb.ConnCase,
    async: true

  alias ZanshinApi.TestSupport.Cabbage.Helpers
  import_feature(ZanshinApi.TestSupport.Cabbage.ScoringSteps)

  setup %{conn: conn} do
    {:ok, %{world: Helpers.new_world(conn)}}
  end
end
