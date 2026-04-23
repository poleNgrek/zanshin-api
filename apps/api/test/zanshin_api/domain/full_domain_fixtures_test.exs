defmodule ZanshinApi.Domain.FullDomainFixturesTest do
  use ZanshinApi.DataCase, async: true

  import ZanshinApi.FullDomainFixtures

  test "full_tournament_fixture/1 builds deterministic cross-domain dataset" do
    dataset = full_tournament_fixture()

    assert dataset.tournament.name == "Spring Kendo Cup"

    assert dataset.divisions.individual.format == :bracket
    assert dataset.divisions.team.format == :team

    assert length(dataset.competitors) == 10
    assert Enum.any?(dataset.competitors, &(&1.display_name == "Kenshi Alpha"))

    assert dataset.matches.individual.state == :completed
    assert length(dataset.team_matches) == 1

    assert length(dataset.medal_results.individual) == 4
    assert length(dataset.medal_results.team) == 2

    assert dataset.special_awards.individual.award_type == :fighting_spirit
    assert dataset.special_awards.team.award_type == :fighting_spirit

    assert dataset.grading.result.final_result == :pass
    assert not is_nil(dataset.grading.result.locked_at)
    assert length(dataset.grading.votes) == 6
  end
end
