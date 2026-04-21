defmodule ZanshinApi.CompetitionsTest do
  use ZanshinApi.DataCase, async: true

  alias ZanshinApi.Competitions
  import ZanshinApi.CompetitionsFixtures

  test "create_tournament/1 persists tournament" do
    assert {:ok, tournament} = Competitions.create_tournament(%{"name" => "Regional Open"})
    assert tournament.name == "Regional Open"
  end

  test "create_division/1 requires valid tournament reference" do
    assert {:error, changeset} =
             Competitions.create_division(%{
               "name" => "U18",
               "format" => "bracket",
               "tournament_id" => Ecto.UUID.generate()
             })

    assert "does not exist" in errors_on(changeset).tournament_id
  end

  test "list_divisions_by_tournament/1 returns only scoped records" do
    t1 = tournament_fixture(%{"name" => "Tournament One"})
    t2 = tournament_fixture(%{"name" => "Tournament Two"})
    d1 = division_fixture(t1, %{"name" => "Open"})
    _d2 = division_fixture(t2, %{"name" => "Women"})

    result = Competitions.list_divisions_by_tournament(t1.id)
    assert Enum.map(result, & &1.id) == [d1.id]
  end
end
