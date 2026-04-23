defmodule ZanshinApi.TestSupport.Cabbage.AnalyticsSteps do
  @moduledoc false

  use ZanshinApi.TestSupport.Cabbage.Feature

  defgiven ~r/^analytics events exist for one tournament and division$/, _, %{world: world} do
    tournament_id = Ecto.UUID.generate()
    division_id = Ecto.UUID.generate()
    match_id = Ecto.UUID.generate()

    {:ok, _transition_event} =
      ZanshinApi.TestSupport.Cabbage.Helpers.create_domain_event(%{
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
      ZanshinApi.TestSupport.Cabbage.Helpers.create_domain_event(%{
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

    world =
      world
      |> ZanshinApi.TestSupport.Cabbage.Helpers.remember(:tournament_id, tournament_id)
      |> ZanshinApi.TestSupport.Cabbage.Helpers.remember(:division_id, division_id)

    {:ok, %{world: world}}
  end

  defgiven ~r/^I am authenticated as "(?<role>[^"]+)"$/, %{role: role}, %{world: world} do
    {:ok, %{world: ZanshinApi.TestSupport.Cabbage.Helpers.with_auth(world, role)}}
  end

  defwhen ~r/^I request analytics feed with limit "(?<limit>\d+)"$/, %{limit: limit}, %{
    world: world
  } do
    tournament_id = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :tournament_id)
    division_id = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :division_id)

    world =
      ZanshinApi.TestSupport.Cabbage.Helpers.get_json(
        world,
        "/api/v1/analytics/events/feed?tournament_id=#{tournament_id}&division_id=#{division_id}&limit=#{limit}"
      )

    {:ok, %{world: world}}
  end

  defthen ~r/^response status is (?<status>\d+)$/, %{status: status}, %{world: world} do
    expected_status = String.to_integer(status)
    payload = json_response(world.last_response, expected_status)

    {:ok,
     %{world: ZanshinApi.TestSupport.Cabbage.Helpers.remember(world, :response_payload, payload)}}
  end

  defthen ~r/^analytics data source is fallback-safe$/, _, %{world: world} do
    payload = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :response_payload)
    data_source = payload["data"]["data_source"]
    assert data_source in ["postgres", "postgres_fallback"]
  end

  defthen ~r/^analytics feed contains (?<count>\d+) events$/, %{count: count}, %{world: world} do
    payload = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :response_payload)
    assert length(payload["data"]["events"]) == String.to_integer(count)
  end
end
