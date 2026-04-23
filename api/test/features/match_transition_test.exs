defmodule ZanshinApi.Features.MatchTransitionTest do
  use ZanshinApi.TestSupport.Cabbage.Feature,
    file: "match_transition.feature",
    template: ZanshinApiWeb.ConnCase,
    async: true

  alias ZanshinApi.TestSupport.Cabbage.Helpers
  import_feature(ZanshinApi.TestSupport.Cabbage.MatchTransitionSteps)

  setup %{conn: conn} do
    {:ok, %{world: Helpers.new_world(conn)}}
  end
end
