defmodule ZanshinApi.MatchesTest do
  use ZanshinApi.DataCase, async: true

  alias ZanshinApi.Matches
  alias ZanshinApi.Matches.MatchEvent
  alias ZanshinApi.Repo
  import ZanshinApi.MatchesFixtures

  describe "create_match/1" do
    test "creates a match with scheduled initial state" do
      assert {:ok, match} = Matches.create_match(valid_match_attrs())
      assert match.state == :scheduled
    end

    test "rejects duplicate competitor assignment" do
      attrs = valid_match_attrs(%{"shiro_competitor_id" => "competitor-a"})

      assert {:error, changeset} = Matches.create_match(attrs)
      assert "must be different from aka competitor" in errors_on(changeset).shiro_competitor_id
    end
  end

  describe "transition_match/3" do
    test "persists state transition and audit event for authorized role" do
      match = match_fixture()

      assert {:ok, updated} = Matches.transition_match(match.id, :prepare, :admin)
      assert updated.state == :ready

      event = Repo.one!(Ecto.assoc(updated, :match_events))

      assert %MatchEvent{
               event: :prepare,
               from_state: :scheduled,
               to_state: :ready,
               actor_role: :admin
             } = event
    end

    test "rejects unauthorized role action" do
      match = match_fixture(%{"state" => "ongoing"})

      assert {:error, :forbidden_transition_for_role} =
               Matches.transition_match(match.id, :complete, :shinpan)
    end
  end
end
