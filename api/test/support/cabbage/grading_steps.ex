defmodule ZanshinApi.TestSupport.Cabbage.GradingSteps do
  @moduledoc false

  use ZanshinApi.TestSupport.Cabbage.Feature

  defgiven ~r/^I am authenticated as "(?<role>[^"]+)"$/, %{role: role}, %{world: world} do
    {:ok, %{world: ZanshinApi.TestSupport.Cabbage.Helpers.with_auth(world, role)}}
  end

  defgiven ~r/^grading prerequisites exist$/, _, %{world: world} do
    tournament = ZanshinApi.CompetitionsFixtures.tournament_fixture()
    competitor = ZanshinApi.CompetitionsFixtures.competitor_fixture()

    world =
      world
      |> ZanshinApi.TestSupport.Cabbage.Helpers.remember(:tournament, tournament)
      |> ZanshinApi.TestSupport.Cabbage.Helpers.remember(:competitor, competitor)

    {:ok, %{world: world}}
  end

  defwhen ~r/^I create a grading session named "(?<name>[^"]+)"$/, %{name: name}, %{world: world} do
    tournament = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :tournament)

    world =
      ZanshinApi.TestSupport.Cabbage.Helpers.post_json(world, "/api/v1/gradings/sessions", %{
        "tournament_id" => tournament.id,
        "name" => name,
        "written_required" => false
      })

    payload = json_response(world.last_response, 201)

    world =
      ZanshinApi.TestSupport.Cabbage.Helpers.remember(world, :session_id, payload["data"]["id"])

    {:ok, %{world: world}}
  end

  defwhen ~r/^I create a grading examiner named "(?<name>[^"]+)"$/, %{name: name}, %{world: world} do
    world =
      ZanshinApi.TestSupport.Cabbage.Helpers.post_json(world, "/api/v1/gradings/examiners", %{
        "display_name" => name,
        "grade" => "7dan",
        "title" => "kyoshi"
      })

    payload = json_response(world.last_response, 201)

    world =
      ZanshinApi.TestSupport.Cabbage.Helpers.remember(world, :examiner_id, payload["data"]["id"])

    {:ok, %{world: world}}
  end

  defwhen ~r/^I assign the examiner as "(?<role>[^"]+)"$/, %{role: role}, %{world: world} do
    session_id = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :session_id)
    examiner_id = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :examiner_id)

    world =
      ZanshinApi.TestSupport.Cabbage.Helpers.post_json(
        world,
        "/api/v1/gradings/sessions/#{session_id}/panel_assignments",
        %{
          "examiner_id" => examiner_id,
          "role" => role
        }
      )

    _payload = json_response(world.last_response, 201)
    {:ok, %{world: world}}
  end

  defwhen ~r/^I create a grading result targeting grade "(?<grade>[^"]+)"$/, %{grade: grade}, %{
    world: world
  } do
    session_id = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :session_id)
    competitor = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :competitor)

    world =
      ZanshinApi.TestSupport.Cabbage.Helpers.post_json(
        world,
        "/api/v1/gradings/sessions/#{session_id}/results",
        %{
          "competitor_id" => competitor.id,
          "target_grade" => grade,
          "declared_stance" => "chudan",
          "jitsugi_result" => "pass",
          "kata_result" => "pass"
        }
      )

    payload = json_response(world.last_response, 201)

    world =
      ZanshinApi.TestSupport.Cabbage.Helpers.remember(world, :result_id, payload["data"]["id"])

    {:ok, %{world: world}}
  end

  defwhen ~r/^I compute the grading result with key "(?<key>[^"]+)"$/, %{key: key}, %{
    world: world
  } do
    result_id = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :result_id)

    world =
      world
      |> ZanshinApi.TestSupport.Cabbage.Helpers.with_idempotency_key(key)
      |> ZanshinApi.TestSupport.Cabbage.Helpers.post_json(
        "/api/v1/gradings/results/#{result_id}/compute",
        %{}
      )

    {:ok, %{world: world}}
  end

  defwhen ~r/^I finalize the grading result with key "(?<key>[^"]+)"$/, %{key: key}, %{
    world: world
  } do
    result_id = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :result_id)

    world =
      world
      |> ZanshinApi.TestSupport.Cabbage.Helpers.with_idempotency_key(key)
      |> ZanshinApi.TestSupport.Cabbage.Helpers.post_json(
        "/api/v1/gradings/results/#{result_id}/finalize",
        %{}
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
    assert ZanshinApi.TestSupport.Cabbage.Helpers.json_path_get(payload, path) == expected
  end

  defthen ~r/^response JSON path "(?<path>[^"]+)" is present$/, %{path: path}, %{world: world} do
    payload = ZanshinApi.TestSupport.Cabbage.Helpers.fetch!(world, :response_payload)
    value = ZanshinApi.TestSupport.Cabbage.Helpers.json_path_get(payload, path)
    assert is_binary(value)
    refute value == ""
  end
end
