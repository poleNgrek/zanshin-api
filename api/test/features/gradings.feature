Feature: Grading workflow behavior
  Grading session/result lifecycle should support compute and finalize actions.

  Scenario: Admin computes and finalizes a grading result
    Given I am authenticated as "admin"
    And grading prerequisites exist
    When I create a grading session named "BDD Session"
    And I create a grading examiner named "BDD Examiner"
    And I assign the examiner as "head"
    And I create a grading result targeting grade "5dan"
    And I compute the grading result with key "bdd-grading-compute-1"
    Then response status is 200
    And response JSON path "data.final_result" equals "pass"
    When I finalize the grading result with key "bdd-grading-finalize-1"
    Then response status is 200
    And response JSON path "data.locked_at" is present
