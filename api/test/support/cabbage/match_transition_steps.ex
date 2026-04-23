defmodule ZanshinApi.TestSupport.Cabbage.MatchTransitionSteps do
  @moduledoc false

  use ZanshinApi.TestSupport.Cabbage.Feature

  defgiven ~r/^a persisted match in state "(?<state>[^"]+)"$/, %{state: match_state}, %{
    world: world
  } do
    match = ZanshinApi.MatchesFixtures.match_fixture(%{"state" => match_state})
    {:ok, %{world: ZanshinApi.TestSupport.Cabbage.Helpers.remember(world, :match, match)}}
  end

  defgiven ~r/^I am authenticated as "(?<role>[^"]+)"$/, %{role: role}, %{world: world} do
    {:ok, %{world: ZanshinApi.TestSupport.Cabbage.Helpers.with_auth(world, role)}}
  end

  defwhen ~r/^I transition the match with event "(?<event>[^"]+)"$/, %{event: event}, %{
    world: world
  } do
    match = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :match)

    world =
      world
      |> ZanshinApi.TestSupport.Cabbage.Helpers.with_idempotency_key(
        "cabbage-match-#{System.unique_integer([:positive])}"
      )
      |> ZanshinApi.TestSupport.Cabbage.Helpers.post_json(
        "/api/v1/matches/#{match.id}/transition",
        %{
          "event" => event
        }
      )

    {:ok, %{world: world}}
  end

  defthen ~r/^response status is (?<status>\d+)$/, %{status: status}, %{world: world} do
    expected_status = String.to_integer(status)
    payload = json_response(world.last_response, expected_status)

    {:ok,
     %{world: ZanshinApi.TestSupport.Cabbage.Helpers.remember(world, :response_payload, payload)}}
  end

  defthen ~r/^response JSON path "(?<path>[^"]+)" equals "(?<value>[^"]+)"$/,
          %{path: path, value: expected},
          %{world: world} do
    payload = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :response_payload)
    actual = ZanshinApi.TestSupport.Cabbage.Helpers.json_path_get(payload, path)
    assert actual == expected
  end
end
