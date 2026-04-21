defmodule ZanshinApi.MatchesFixtures do
  @moduledoc false

  alias ZanshinApi.Matches

  def valid_match_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        "tournament_id" => "tourn-001",
        "division_id" => "division-open",
        "aka_competitor_id" => "competitor-a",
        "shiro_competitor_id" => "competitor-b"
      },
      overrides
    )
  end

  def match_fixture(overrides \\ %{}) do
    attrs = valid_match_attrs(overrides)
    {:ok, match} = Matches.create_match(attrs)
    match
  end
end
