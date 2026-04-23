Feature: API domain regression coverage
  Existing domain and context ExUnit tests are mirrored as Gherkin scenarios.

  Scenario Outline: Domain regression scenario
    Given the domain test suite is configured
    When I validate "<exunit_test_case>"
    Then its behavior is described in this Gherkin coverage matrix

    Examples:
      | exunit_test_case |
      | verify_token/1 validates RS256 token against configured JWKS |
      | verify_token/1 rejects malformed token |
      | generate_token/3 and verify_token/1 round trip |
      | allows valid lifecycle transitions |
      | rejects invalid transition |
      | parse_event/1 accepts known events and rejects unknown event |
      | parse_state/1 accepts known states and rejects unknown state |
      | create_result/2 sets pending with carryover when kata fails |
      | create_result/2 allows pass with written waived when not required |
      | compute_result_decision/1 applies quorum and finalize_result/2 locks result |
      | create_vote/2 rejects examiner not assigned to the result session |
      | create_tournament/1 persists tournament |
      | create_competitor/1 accepts photo_url alias into avatar_url |
      | create_division/1 requires valid tournament reference |
      | list_divisions_by_tournament/1 returns only scoped records |
      | list_division_stages/1 returns progression plan by sequence |
      | creates podium medals with two bronze entries and no fourth place |
      | team divisions award medals to team and fighting spirit to one player |
      | compute_division_results/1 derives gold silver and dual bronze from bracket matches |
      | export_tournament_snapshot/1 returns nested tournament data |
      | compute_division_results/1 derives team podium and supports representative match |
      | creates a match with scheduled initial state |
      | rejects duplicate competitor assignment |
      | rejects when division does not belong to tournament |
      | persists state transition and audit event for authorized role |
      | rejects unauthorized role action |
      | records ippon for ongoing match by shinpan |
      | rejects scoring when match is not ongoing |
      | rejects forbidden role for scoring |
      | rejects tsuki when division rule disallows it |
      | all required domain model modules exist |
      | full_tournament_fixture/1 builds deterministic cross-domain dataset |
      | match_summary/1 reads from neo4j when configured |
      | match_summary/1 falls back to postgres when neo4j read fails |
      | projects unprocessed match transition event and advances checkpoint |
      | projection failure leaves event unprocessed and without checkpoint |
      | retry succeeds after transient projection failure |
      | projects events in insertion order and checkpoints last projected event |
      | second replay pass is idempotent when no events remain |
      | replayed stale event does not regress checkpoint after newer projection |
      | start pause resume and overtime commands produce auditable timer events |
      | rejects invalid timer transitions and forbidden roles |
