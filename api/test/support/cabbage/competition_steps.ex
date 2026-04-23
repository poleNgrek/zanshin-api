defmodule ZanshinApi.TestSupport.Cabbage.CompetitionSteps do
  @moduledoc false

  use ZanshinApi.TestSupport.Cabbage.Feature

  defgiven ~r/^tournaments exist for listing coverage$/, _, %{world: world} do
    _t1 = ZanshinApi.CompetitionsFixtures.tournament_fixture(%{"name" => "BDD Cup 1"})
    _t2 = ZanshinApi.CompetitionsFixtures.tournament_fixture(%{"name" => "BDD Cup 2"})
    _t3 = ZanshinApi.CompetitionsFixtures.tournament_fixture(%{"name" => "BDD Cup 3"})
    {:ok, %{world: world}}
  end

  defgiven ~r/^I am authenticated as "(?<role>[^"]+)"$/, %{role: role}, %{world: world} do
    {:ok, %{world: ZanshinApi.TestSupport.Cabbage.Helpers.with_auth(world, role)}}
  end

  defgiven ~r/^a tournament with one division exists$/, _, %{world: world} do
    tournament = ZanshinApi.CompetitionsFixtures.tournament_fixture()
    _division = ZanshinApi.CompetitionsFixtures.division_fixture(tournament)

    {:ok,
     %{world: ZanshinApi.TestSupport.Cabbage.Helpers.remember(world, :tournament, tournament)}}
  end

  defwhen ~r/^I list tournaments with limit "(?<limit>\d+)" and offset "(?<offset>\d+)"$/,
          %{limit: limit, offset: offset},
          %{world: world} do
    world =
      ZanshinApi.TestSupport.Cabbage.Helpers.get_json(
        world,
        "/api/v1/tournaments?limit=#{limit}&offset=#{offset}"
      )

    {:ok, %{world: world}}
  end

  defwhen ~r/^I create a tournament named "(?<name>[^"]+)"$/, %{name: name}, %{world: world} do
    world =
      ZanshinApi.TestSupport.Cabbage.Helpers.post_json(world, "/api/v1/tournaments", %{
        "name" => name
      })

    {:ok, %{world: world}}
  end

  defwhen ~r/^I export the prepared tournament$/, _, %{world: world} do
    tournament = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :tournament)

    world =
      ZanshinApi.TestSupport.Cabbage.Helpers.get_json(
        world,
        "/api/v1/tournaments/#{tournament.id}/export"
      )

    {:ok, %{world: world}}
  end

  defthen ~r/^response status is (?<status>\d+)$/, %{status: status}, %{world: world} do
    expected_status = String.to_integer(status)
    payload = json_response(world.last_response, expected_status)

    {:ok,
     %{world: ZanshinApi.TestSupport.Cabbage.Helpers.remember(world, :response_payload, payload)}}
  end

  defthen ~r/^pagination limit is (?<value>\d+)$/, %{value: value}, %{world: world} do
    payload = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :response_payload)
    assert payload["pagination"]["limit"] == String.to_integer(value)
  end

  defthen ~r/^pagination offset is (?<value>\d+)$/, %{value: value}, %{world: world} do
    payload = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :response_payload)
    assert payload["pagination"]["offset"] == String.to_integer(value)
  end

  defthen ~r/^pagination count is (?<value>\d+)$/, %{value: value}, %{world: world} do
    payload = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :response_payload)
    assert payload["pagination"]["count"] == String.to_integer(value)
  end

  defthen ~r/^response JSON path "(?<path>[^"]+)" equals "(?<value>[^"]+)"$/,
          %{path: path, value: expected},
          %{world: world} do
    payload = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :response_payload)
    assert ZanshinApi.TestSupport.Cabbage.Helpers.json_path_get(payload, path) == expected
  end

  defthen ~r/^response JSON path "(?<path>[^"]+)" equals number (?<value>\d+)$/,
          %{path: path, value: expected},
          %{world: world} do
    payload = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :response_payload)

    assert ZanshinApi.TestSupport.Cabbage.Helpers.json_path_get(payload, path) ==
             String.to_integer(expected)
  end
end
