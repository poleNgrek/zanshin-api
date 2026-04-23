defmodule ZanshinApi.TestSupport.Cabbage.ScoringSteps do
  @moduledoc false

  use ZanshinApi.TestSupport.Cabbage.Feature

  defgiven ~r/^an ongoing match exists$/, _, %{world: world} do
    match = ZanshinApi.MatchesFixtures.match_fixture(%{"state" => "ongoing"})
    {:ok, %{world: ZanshinApi.TestSupport.Cabbage.Helpers.remember(world, :match, match)}}
  end

  defgiven ~r/^I am authenticated as "(?<role>[^"]+)"$/, %{role: role}, %{world: world} do
    {:ok, %{world: ZanshinApi.TestSupport.Cabbage.Helpers.with_auth(world, role)}}
  end

  defgiven ~r/^score events exist for pagination checks$/, _, %{world: world} do
    match = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :match)

    world =
      world
      |> ZanshinApi.TestSupport.Cabbage.Helpers.score_match(
        match.id,
        "bdd-score-page-1",
        "aka",
        "men"
      )
      |> ZanshinApi.TestSupport.Cabbage.Helpers.score_match(
        match.id,
        "bdd-score-page-2",
        "shiro",
        "do"
      )

    {:ok, %{world: world}}
  end

  defwhen ~r/^I score the match with key "(?<key>[^"]+)" for side "(?<side>[^"]+)"$/,
          %{key: key, side: side},
          %{world: world} do
    match = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :match)
    world = ZanshinApi.TestSupport.Cabbage.Helpers.score_match(world, match.id, key, side, "men")
    {:ok, %{world: world}}
  end

  defwhen ~r/^I list score events with limit "(?<limit>\d+)" and offset "(?<offset>\d+)"$/,
          %{limit: limit, offset: offset},
          %{world: world} do
    match = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :match)

    world =
      ZanshinApi.TestSupport.Cabbage.Helpers.get_json(
        world,
        "/api/v1/matches/#{match.id}/score?limit=#{limit}&offset=#{offset}"
      )

    {:ok, %{world: world}}
  end

  defthen ~r/^response status is (?<status>\d+)$/, %{status: status}, %{world: world} do
    expected_status = String.to_integer(status)
    payload = json_response(world.last_response, expected_status)

    {:ok,
     %{world: ZanshinApi.TestSupport.Cabbage.Helpers.remember(world, :response_payload, payload)}}
  end

  defthen ~r/^I remember the latest score id$/, _, %{world: world} do
    payload = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :response_payload)
    remembered_id = payload["data"]["id"]

    {:ok,
     %{
       world:
         ZanshinApi.TestSupport.Cabbage.Helpers.remember(
           world,
           :remembered_score_id,
           remembered_id
         )
     }}
  end

  defthen ~r/^response header "(?<header>[^"]+)" equals "(?<value>[^"]+)"$/,
          %{header: header, value: value},
          %{world: world} do
    assert get_resp_header(world.last_response, header) == [value]
  end

  defthen ~r/^latest score id matches remembered score id$/, _, %{world: world} do
    payload = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :response_payload)
    remembered_id = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :remembered_score_id)
    assert payload["data"]["id"] == remembered_id
  end

  defthen ~r/^score pagination limit is (?<value>\d+)$/, %{value: value}, %{world: world} do
    payload = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :response_payload)
    assert payload["pagination"]["limit"] == String.to_integer(value)
  end

  defthen ~r/^score pagination offset is (?<value>\d+)$/, %{value: value}, %{world: world} do
    payload = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :response_payload)
    assert payload["pagination"]["offset"] == String.to_integer(value)
  end

  defthen ~r/^score pagination count is (?<value>\d+)$/, %{value: value}, %{world: world} do
    payload = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :response_payload)
    assert payload["pagination"]["count"] == String.to_integer(value)
  end
end
