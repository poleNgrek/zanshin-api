defmodule ZanshinApi.MatchesTest do
  use ZanshinApi.DataCase, async: true

  alias ZanshinApi.Competitions
  alias ZanshinApi.Events.DomainEvent
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

    test "rejects when division does not belong to tournament" do
      tournament_a = tournament_fixture(%{"name" => "Tournament A"})
      tournament_b = tournament_fixture(%{"name" => "Tournament B"})
      division_b = division_fixture(tournament_b, %{"name" => "Division B"})
      aka = competitor_fixture()
      shiro = competitor_fixture()

      assert {:error, :division_not_in_tournament} =
               Matches.create_match(%{
                 "tournament_id" => tournament_a.id,
                 "division_id" => division_b.id,
                 "aka_competitor_id" => aka.id,
                 "shiro_competitor_id" => shiro.id
               })
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

      domain_event =
        Repo.one!(
          from e in DomainEvent,
            where: e.aggregate_type == "match" and e.aggregate_id == ^updated.id,
            order_by: [asc: e.inserted_at],
            limit: 1
        )

      assert domain_event.event_type == "match.transitioned"
      assert domain_event.payload["event"] == "prepare"
      assert domain_event.payload["from_state"] == "scheduled"
      assert domain_event.payload["to_state"] == "ready"
      assert domain_event.causation_id == event.id
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

      domain_event =
        Repo.one!(
          from e in DomainEvent,
            where:
              e.aggregate_type == "match" and e.aggregate_id == ^match.id and
                e.event_type == "match.score_recorded",
            order_by: [desc: e.inserted_at],
            limit: 1
        )

      assert domain_event.payload["score_event_id"] == score_event.id
      assert domain_event.payload["score_type"] == "ippon"
      assert domain_event.payload["side"] == "aka"
      assert domain_event.payload["target"] == "men"
      assert domain_event.causation_id == score_event.id
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

  describe "timer command/event model" do
    test "start pause resume and overtime commands produce auditable timer events" do
      match = match_fixture(%{"state" => "ongoing"})

      t0 = ~U[2026-04-23 12:00:00Z]
      t1 = ~U[2026-04-23 12:00:30Z]
      t2 = ~U[2026-04-23 12:00:45Z]
      t3 = ~U[2026-04-23 12:01:15Z]
      t4 = ~U[2026-04-23 12:01:45Z]

      assert {:ok, timer_running} = Matches.start_timer(match.id, :timekeeper, t0)
      assert timer_running.status == :running
      assert timer_running.elapsed_ms == 0

      assert {:ok, timer_paused} = Matches.pause_timer(match.id, :timekeeper, t1)
      assert timer_paused.status == :paused
      assert timer_paused.elapsed_ms == 30_000

      assert {:ok, timer_resumed} = Matches.resume_timer(match.id, :timekeeper, t2)
      assert timer_resumed.status == :running
      assert timer_resumed.elapsed_ms == 30_000

      assert {:ok, timer_overtime} = Matches.enter_overtime(match.id, :admin, t3)
      assert timer_overtime.status == :overtime

      assert {:ok, final_timer} = Matches.pause_timer(match.id, :timekeeper, t4)
      assert final_timer.status == :paused
      assert final_timer.elapsed_ms == 90_000

      events = Matches.list_timer_events(match.id)
      assert Enum.map(events, & &1.command) == [:start, :pause, :resume, :overtime, :pause]
      assert Enum.map(events, & &1.to_status) == [:running, :paused, :running, :overtime, :paused]
      assert List.last(events).elapsed_after_ms == 90_000

      assert {:ok, reconstructed} = Matches.reconstruct_timer(match.id)
      assert reconstructed.status == :paused
      assert reconstructed.elapsed_ms == 90_000
      assert is_nil(reconstructed.run_started_at)
    end

    test "rejects invalid timer transitions and forbidden roles" do
      match = match_fixture(%{"state" => "ongoing"})
      now = ~U[2026-04-23 13:00:00Z]

      assert {:error, :invalid_timer_transition} = Matches.pause_timer(match.id, :timekeeper, now)

      assert {:error, :forbidden_timer_command_for_role} =
               Matches.start_timer(match.id, :shinpan, now)
    end
  end
end
