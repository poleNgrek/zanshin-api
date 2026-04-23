Feature: Analytics fallback behavior
  Analytics feed should succeed with postgres or postgres_fallback data source.

  Scenario: Admin fetches analytics feed with fallback-safe data source value
    Given analytics events exist for one tournament and division
    And I am authenticated as "admin"
    When I request analytics feed with limit "10"
    Then response status is 200
    And analytics data source is fallback-safe
    And analytics feed contains 2 events
