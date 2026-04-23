Feature: Match transition API behavior
  API commands should honor auth and state transition rules.

  Scenario: Admin transitions a scheduled match to ready
    Given a persisted match in state "scheduled"
    And I am authenticated as "admin"
    When I transition the match with event "prepare"
    Then response status is 200
    And response JSON path "data.new_state" equals "ready"

  Scenario: Shinpan cannot complete an ongoing match
    Given a persisted match in state "ongoing"
    And I am authenticated as "shinpan"
    When I transition the match with event "complete"
    Then response status is 403
    And response JSON path "error" equals "forbidden_transition_for_role"
