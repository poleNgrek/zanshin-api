defmodule ZanshinApi.MatchesTest do
  use ZanshinApi.DataCase, async: true

  alias ZanshinApi.Competitions
  alias ZanshinApi.Matches
  alias ZanshinApi.Matches.MatchEvent
  alias ZanshinApi.Repo
  import ZanshinApi.CompetitionsFixtures
  import ZanshinApi.MatchesFixtures

  describe "create_match/1" do
    test "creates a match with scheduled initial state" do
      assert {:ok, match} = Matches.create_match(valid_match_attrs())
      assert match.state == :scheduled
    end

    test "rejects duplicate competitor assignment" do
      base = valid_match_attrs()
      attrs = Map.put(base, "shiro_competitor_id", base["aka_competitor_id"])

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

  describe "record_score_event/4" do
    test "records ippon for ongoing match by shinpan" do
      match = match_fixture(%{"state" => "ongoing"})

      assert {:ok, score_event} =
               Matches.record_score_event(match.id, :ippon, :aka, :men, :shinpan)

      assert score_event.score_type == :ippon
      assert score_event.side == :aka
      assert score_event.actor_role == :shinpan
      assert score_event.target == :men
    end

    test "rejects scoring when match is not ongoing" do
      match = match_fixture(%{"state" => "ready"})

      assert {:error, :match_not_ongoing} =
               Matches.record_score_event(match.id, :hansoku, :shiro, nil, :shinpan)
    end

    test "rejects forbidden role for scoring" do
      match = match_fixture(%{"state" => "ongoing"})

      assert {:error, :forbidden_score_for_role} =
               Matches.record_score_event(match.id, :ippon, :aka, :men, :timekeeper)
    end

    test "rejects tsuki when division rule disallows it" do
      match = match_fixture(%{"state" => "ongoing"})
      division = Competitions.list_divisions_by_tournament(match.tournament_id) |> List.first()

      _rule =
        division_rule_fixture(division, %{"allow_tsuki" => false, "age_group" => "children"})

      assert {:error, :tsuki_not_allowed} =
               Matches.record_score_event(match.id, :ippon, :aka, :tsuki, :shinpan)
    end
  end
end
