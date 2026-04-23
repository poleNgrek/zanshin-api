defmodule ZanshinApi.TestSupport.Gherkin do
  @moduledoc false

  @type step :: %{keyword: :given | :when | :then, text: String.t()}
  @type scenario :: %{name: String.t(), steps: [step()]}

  @spec parse_feature!(String.t()) :: [scenario()]
  def parse_feature!(path) do
    path
    |> File.read!()
    |> String.split("\n")
    |> Enum.reduce(
      %{scenarios: [], current: nil, last_keyword: nil},
      &parse_line/2
    )
    |> finalize()
  end

  defp parse_line(line, state) do
    trimmed = String.trim(line)

    cond do
      trimmed == "" ->
        state

      String.starts_with?(trimmed, "#") ->
        state

      String.starts_with?(trimmed, "Feature:") ->
        state

      String.starts_with?(trimmed, "Scenario:") ->
        scenario_name =
          trimmed
          |> String.replace_prefix("Scenario:", "")
          |> String.trim()

        state
        |> flush_current()
        |> Map.put(:current, %{name: scenario_name, steps: []})
        |> Map.put(:last_keyword, nil)

      step_line?(trimmed) ->
        append_step(trimmed, state)

      is_nil(state.current) ->
        state

      true ->
        raise ArgumentError, "Unsupported Gherkin line: #{trimmed}"
    end
  end

  defp step_line?(line) do
    String.starts_with?(line, "Given ") or
      String.starts_with?(line, "When ") or
      String.starts_with?(line, "Then ") or
      String.starts_with?(line, "And ")
  end

  defp append_step(trimmed, %{current: nil}) do
    raise ArgumentError, "Step declared outside scenario: #{trimmed}"
  end

  defp append_step(trimmed, state) do
    {raw_keyword, text} =
      case String.split(trimmed, " ", parts: 2) do
        [keyword, rest] -> {keyword, String.trim(rest)}
        _ -> raise ArgumentError, "Invalid step syntax: #{trimmed}"
      end

    keyword =
      case raw_keyword do
        "Given" -> :given
        "When" -> :when
        "Then" -> :then
        "And" -> state.last_keyword || :given
      end

    current = state.current
    next_step = %{keyword: keyword, text: text}
    updated_current = %{current | steps: current.steps ++ [next_step]}

    %{state | current: updated_current, last_keyword: keyword}
  end

  defp flush_current(%{current: nil} = state), do: state

  defp flush_current(%{scenarios: scenarios, current: current} = state) do
    %{state | scenarios: scenarios ++ [current], current: nil}
  end

  defp finalize(state) do
    finished = flush_current(state)
    finished.scenarios
  end
end
