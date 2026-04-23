defmodule ZanshinApiWeb.MatchStateGherkinTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.AuthHelpers
  import ZanshinApi.MatchesFixtures

  alias ZanshinApi.TestSupport.Gherkin

  @moduletag :gherkin
  @feature_path Path.expand("../../features/match_transition.feature", __DIR__)
  @scenarios Gherkin.parse_feature!(@feature_path)

  for scenario <- @scenarios do
    @scenario_name scenario.name
    @scenario_steps scenario.steps

    test "Gherkin scenario: #{@scenario_name}", %{conn: conn} do
      _final_context =
        Enum.reduce(@scenario_steps, %{conn: conn}, fn step, context ->
          execute_step(step, context, @scenario_name)
        end)
    end
  end

  defp execute_step(%{keyword: :given, text: step_text}, context, _scenario_name) do
    cond do
      Regex.match?(~r/^a persisted match in state "([^"]+)"$/, step_text) ->
        [_, state] = Regex.run(~r/^a persisted match in state "([^"]+)"$/, step_text)
        match = match_fixture(%{"state" => state})
        Map.put(context, :match, match)

      Regex.match?(~r/^I am authenticated as "([^"]+)"$/, step_text) ->
        [_, role] = Regex.run(~r/^I am authenticated as "([^"]+)"$/, step_text)

        authenticated_conn =
          put_req_header(context.conn, "authorization", bearer_token_for(role))

        Map.put(context, :conn, authenticated_conn)

      true ->
        raise "Unsupported Given step: #{step_text}"
    end
  end

  defp execute_step(%{keyword: :when, text: step_text}, context, scenario_name) do
    case Regex.run(~r/^I transition the match with event "([^"]+)"$/, step_text) do
      [_, event] ->
        response_conn =
          context.conn
          |> put_req_header(
            "idempotency-key",
            "gherkin-#{:erlang.phash2("#{scenario_name}-#{event}")}"
          )
          |> post("/api/v1/matches/#{context.match.id}/transition", %{"event" => event})

        Map.put(context, :response_conn, response_conn)

      _ ->
        raise "Unsupported When step: #{step_text}"
    end
  end

  defp execute_step(%{keyword: :then, text: step_text}, context, _scenario_name) do
    cond do
      Regex.match?(~r/^response status is \d+$/, step_text) ->
        [status] = Regex.run(~r/\d+$/, step_text)
        expected_status = String.to_integer(status)
        response_payload = json_response(context.response_conn, expected_status)
        Map.put(context, :response_payload, response_payload)

      Regex.match?(~r/^response JSON path "([^"]+)" equals "([^"]+)"$/, step_text) ->
        [_, json_path, expected_value] =
          Regex.run(~r/^response JSON path "([^"]+)" equals "([^"]+)"$/, step_text)

        response_payload = context[:response_payload] || json_response(context.response_conn, 200)
        actual_value = json_path_get(response_payload, json_path)

        assert actual_value == expected_value
        context

      true ->
        raise "Unsupported Then step: #{step_text}"
    end
  end

  defp execute_step(%{keyword: _unsupported, text: step_text}, _context, _scenario_name) do
    raise "Unsupported step: #{step_text}"
  end

  defp json_path_get(payload, path) do
    path
    |> String.split(".")
    |> Enum.reduce(payload, fn segment, acc ->
      case acc do
        %{} -> Map.get(acc, segment)
        _ -> nil
      end
    end)
  end
end
