Feature: Match scoring idempotency and pagination behavior
  Score commands should be replay-safe and score listing should expose pagination metadata.

  Scenario: Score command replays response for repeated idempotency key
    Given an ongoing match exists
    And I am authenticated as "shinpan"
    When I score the match with key "bdd-score-idem-1" for side "aka"
    Then response status is 201
    And I remember the latest score id
    When I score the match with key "bdd-score-idem-1" for side "aka"
    Then response status is 201
    And response header "x-idempotent-replayed" equals "true"
    And latest score id matches remembered score id

  Scenario: Score listing returns pagination metadata
    Given an ongoing match exists
    And I am authenticated as "shinpan"
    And score events exist for pagination checks
    When I list score events with limit "1" and offset "1"
    Then response status is 200
    And score pagination limit is 1
    And score pagination offset is 1
    And score pagination count is 1
