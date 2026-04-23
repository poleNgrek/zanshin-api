export const fixtureIds = {
  tournament: "d4499989-6f77-4466-9c47-5205156f0ed6",
  division: "9583d485-a8f6-4918-b8ca-a89b5838c7ac",
  gradingSession: "1fc86665-4dd6-4f3c-af3a-faf9c746d70f",
  gradingResult: "bc178577-233f-40a7-a0d1-a53bb8ff3636",
  match: "b06e1842-c8ef-49f6-bbd5-d22f0dd96078",
  competitorOne: "22f36686-cc3a-478c-a5a1-7a58faec1e9f",
  competitorTwo: "cad9d450-e970-48f7-abcc-b494a9532474"
};

export const fixtureData = {
  tournament: {
    id: fixtureIds.tournament,
    name: "Spring Cup",
    location: "Kyoto",
    starts_on: "2026-05-20"
  },
  division: {
    id: fixtureIds.division,
    tournament_id: fixtureIds.tournament,
    name: "Adult Individual",
    format: "bracket"
  },
  gradingSession: {
    id: fixtureIds.gradingSession,
    tournament_id: fixtureIds.tournament,
    name: "Spring Shinsa"
  },
  gradingResult: {
    id: fixtureIds.gradingResult,
    grading_session_id: fixtureIds.gradingSession,
    competitor_id: fixtureIds.competitorOne,
    target_grade: "4dan",
    final_result: "pending",
    jitsugi_result: "not_attempted",
    kata_result: "not_attempted",
    written_result: "not_attempted"
  },
  gradingComputedResult: {
    id: fixtureIds.gradingResult,
    grading_session_id: fixtureIds.gradingSession,
    competitor_id: fixtureIds.competitorOne,
    target_grade: "4dan",
    final_result: "pending",
    jitsugi_result: "pass",
    kata_result: "not_attempted",
    written_result: "not_attempted"
  },
  gradingFinalizedResult: {
    id: fixtureIds.gradingResult,
    grading_session_id: fixtureIds.gradingSession,
    competitor_id: fixtureIds.competitorOne,
    target_grade: "4dan",
    final_result: "pending",
    jitsugi_result: "pass",
    kata_result: "not_attempted",
    written_result: "not_attempted",
    locked_at: "2026-04-21T12:00:00Z"
  },
  competitors: [
    { id: fixtureIds.competitorOne, display_name: "Kenshi One" },
    { id: fixtureIds.competitorTwo, display_name: "Kenshi Two" }
  ],
  match: {
    id: fixtureIds.match,
    tournament_id: fixtureIds.tournament,
    division_id: fixtureIds.division,
    aka_competitor_id: fixtureIds.competitorOne,
    shiro_competitor_id: fixtureIds.competitorTwo,
    state: "scheduled",
    inserted_at: "2026-04-21T09:44:00Z"
  },
  analyticsOverview: {
    scope: {
      tournament_id: fixtureIds.tournament,
      division_id: fixtureIds.division,
      from: null,
      to: null
    },
    data_source: "neo4j",
    summary: {
      kpis: {
        total_events: 4,
        transition_events: 3,
        score_events: 1
      },
      event_type_breakdown: [
        { event_type: "match.transitioned", count: 3 },
        { event_type: "match.score_recorded", count: 1 }
      ]
    },
    state_overview: {
      state_counts: [
        { state: "ready", count: 1 },
        { state: "ongoing", count: 1 }
      ]
    },
    insights: {
      throughput_trend: [
        {
          bucket_start: "2026-04-21T10:00:00Z",
          total_events: 4,
          transition_events: 3,
          score_events: 1
        }
      ],
      top_active_matches: [{ match_id: fixtureIds.match, event_count: 4 }],
      actor_role_activity: [{ actor_role: "admin", event_count: 4 }]
    },
    recent_events: [
      {
        event_id: "4726f343-f254-4efa-8130-f9856c699d0f",
        event_type: "match.transitioned",
        aggregate_id: fixtureIds.match,
        occurred_at: "2026-04-21T10:01:00Z",
        payload: { to_state: "ongoing" }
      }
    ]
  }
};
