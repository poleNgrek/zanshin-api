Feature: Competitions API behavior
  Tournament listing, creation, and export should remain stable.

  Scenario: Public tournament listing includes pagination metadata
    Given tournaments exist for listing coverage
    When I list tournaments with limit "1" and offset "1"
    Then response status is 200
    And pagination limit is 1
    And pagination offset is 1
    And pagination count is 1

  Scenario: Admin can create a tournament
    Given I am authenticated as "admin"
    When I create a tournament named "BDD Cup"
    Then response status is 201
    And response JSON path "data.name" equals "BDD Cup"

  Scenario: Admin can export a tournament snapshot
    Given I am authenticated as "admin"
    And a tournament with one division exists
    When I export the prepared tournament
    Then response status is 200
    And response JSON path "data.metadata.schema_version" equals number 1
