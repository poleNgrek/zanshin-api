Feature: API controller regression coverage
  Existing controller-level API tests are mirrored as Gherkin scenarios.

  Scenario Outline: Controller regression scenario
    Given the API test suite is configured
    When I validate "<exunit_test_case>"
    Then its behavior is described in this Gherkin coverage matrix

    Examples:
      | exunit_test_case |
      | serves swagger docs html |
      | serves openapi static document |
      | POST /api/v1/matches creates a match for admin role |
      | POST /api/v1/matches rejects unauthorized role |
      | POST /api/v1/matches requires auth |
      | GET /api/v1/matches/:id returns persisted match |
      | GET /api/v1/matches supports standardized pagination |
      | POST /api/v1/matches rejects mismatched tournament and division |
      | GET /api/v1/tournaments lists tournaments without auth |
      | GET /api/v1/tournaments applies limit and offset |
      | GET /api/v1/tournaments rejects invalid pagination params |
      | POST /api/v1/tournaments requires auth |
      | POST /api/v1/tournaments allows admin |
      | GET /api/v1/tournaments/:id/export returns tournament snapshot for admin |
      | GET /api/v1/gradings/sessions requires tournament_id query param |
      | GET /api/v1/gradings/sessions lists sessions by tournament_id |
      | POST /api/v1/matches/:id/transition transitions a persisted match |
      | POST /api/v1/matches/:id/transition rejects forbidden role transition |
      | POST /api/v1/matches/:id/transition requires JWT auth |
      | POST /api/v1/matches/:id/transition replays response for same idempotency key |
      | POST /api/v1/matches/:id/transition rejects missing idempotency key |
      | POST /api/v1/matches/:id/transition rejects key reuse for different payload |
      | GET /api/v1/analytics/matches/summary requires auth |
      | GET /api/v1/analytics/matches/summary returns scoped summary data |
      | GET /api/v1/analytics/matches/summary requires tournament_id |
      | GET /api/v1/divisions requires tournament_id query param |
      | GET /api/v1/divisions lists divisions for tournament_id |
      | GET /api/v1/divisions rejects invalid pagination params |
      | GET /api/v1/analytics/events/feed returns scoped event list |
      | GET /api/v1/analytics/matches/state_overview returns grouped states |
      | GET /api/v1/analytics/dashboard/overview returns consolidated payload |
      | analytics dashboard endpoints require auth |
      | grading API supports session, panel, result, vote, and note flow |
      | grading vote rejects examiner not assigned to result session |
      | grading compute replays response for same idempotency key |
      | adds CORS headers for allowed origin |
      | handles CORS preflight with no-content response |
      | POST /api/v1/division_stages creates stage for division progression |
      | GET /api/v1/division_stages lists stages publicly by division |
      | GET /api/v1/division_stages requires division_id query param |
      | POST /api/v1/competitors stores stance and grade profile |
      | PUT /api/v1/divisions/:id/rules upserts rule set |
      | GET /api/v1/health returns service status |
      | POST /api/v1/teams creates team and member with taisho position |
      | POST /api/v1/team_matches creates completed match with representative winner |
      | POST /api/v1/team_matches rejects team outside division |
      | POST /api/v1/matches/:id/score records score for ongoing match |
      | POST /api/v1/matches/:id/score rejects score when match is not ongoing |
      | POST /api/v1/matches/:id/score rejects forbidden role |
      | POST /api/v1/matches/:id/score rejects tsuki when disallowed by rules |
      | POST /api/v1/matches/:id/score replays response for same idempotency key |
      | GET /api/v1/matches/:id/score supports pagination metadata |
      | POST /api/v1/division_medal_results enforces two bronze winners only |
      | POST /api/v1/division_special_awards creates fighting spirit award |
      | POST /api/v1/divisions/:id/compute_results computes podium from bracket results |
      | joins tournament and match topics and receives transition realtime event |
      | receives score realtime event on tournament topic |
      | receives timer realtime event on match topic |
      | GET /api/v1/realtime/matches/stream emits SSE snapshot for admin |
      | GET /api/v1/realtime/matches/stream requires tournament_id |
      | GET /api/v1/realtime/matches/stream forbids non-admin |
