defmodule ZanshinApi.Features.GradingsTest do
  use ZanshinApi.TestSupport.Cabbage.Feature,
    file: "gradings.feature",
    template: ZanshinApiWeb.ConnCase,
    async: true

  alias ZanshinApi.TestSupport.Cabbage.Helpers
  import_feature(ZanshinApi.TestSupport.Cabbage.GradingSteps)

  setup %{conn: conn} do
    {:ok, %{world: Helpers.new_world(conn)}}
  end
end
