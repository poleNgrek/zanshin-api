defmodule ZanshinApi.GherkinCoverageCatalogTest do
  use ExUnit.Case, async: true

  @feature_paths [
    Path.expand("../features/controller_regression_coverage.feature", __DIR__),
    Path.expand("../features/domain_regression_coverage.feature", __DIR__)
  ]

  test "every ExUnit test case is represented in Gherkin coverage matrices" do
    exunit_case_names = discover_exunit_case_names()
    gherkin_case_names = discover_gherkin_case_names()

    missing_from_gherkin =
      exunit_case_names
      |> MapSet.difference(gherkin_case_names)
      |> MapSet.to_list()
      |> Enum.sort()

    orphaned_in_gherkin =
      gherkin_case_names
      |> MapSet.difference(exunit_case_names)
      |> MapSet.to_list()
      |> Enum.sort()

    assert missing_from_gherkin == [],
           "Missing Gherkin scenarios for ExUnit tests:\n- #{Enum.join(missing_from_gherkin, "\n- ")}"

    assert orphaned_in_gherkin == [],
           "Gherkin scenarios without matching ExUnit tests:\n- #{Enum.join(orphaned_in_gherkin, "\n- ")}"
  end

  defp discover_exunit_case_names do
    Path.wildcard(Path.expand("../**/*_test.exs", __DIR__))
    |> Enum.reject(&String.ends_with?(&1, "match_state_gherkin_test.exs"))
    |> Enum.reject(&String.ends_with?(&1, "gherkin_coverage_catalog_test.exs"))
    |> Enum.flat_map(fn path ->
      path
      |> File.read!()
      |> then(&Regex.scan(~r/test\s+"([^"]+)"/, &1, capture: :all_but_first))
      |> Enum.map(fn [case_name] -> String.trim(case_name) end)
    end)
    |> MapSet.new()
  end

  defp discover_gherkin_case_names do
    @feature_paths
    |> Enum.flat_map(fn path ->
      path
      |> File.read!()
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.filter(fn line ->
        String.starts_with?(line, "|") and
          String.ends_with?(line, "|") and
          line != "| exunit_test_case |"
      end)
      |> Enum.map(fn line ->
        line
        |> String.trim_leading("|")
        |> String.trim_trailing("|")
        |> String.trim()
      end)
    end)
    |> MapSet.new()
  end
end
