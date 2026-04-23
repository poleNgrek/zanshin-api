defmodule ZanshinApi.Features.CompetitionsTest do
  use ZanshinApi.TestSupport.Cabbage.Feature,
    file: "competitions.feature",
    template: ZanshinApiWeb.ConnCase,
    async: true

  alias ZanshinApi.TestSupport.Cabbage.Helpers
  import_feature(ZanshinApi.TestSupport.Cabbage.CompetitionSteps)

  setup %{conn: conn} do
    {:ok, %{world: Helpers.new_world(conn)}}
  end
end
