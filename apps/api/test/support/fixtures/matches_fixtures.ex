defmodule ZanshinApi.MatchesFixtures do
  @moduledoc false

  alias ZanshinApi.Matches
  import ZanshinApi.CompetitionsFixtures

  def valid_match_attrs(overrides \\ %{}) do
    tournament = tournament_fixture()
    division = division_fixture(tournament)
    aka = competitor_fixture()
    shiro = competitor_fixture()

    Map.merge(
      %{
        "tournament_id" => tournament.id,
        "division_id" => division.id,
        "aka_competitor_id" => aka.id,
        "shiro_competitor_id" => shiro.id
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
