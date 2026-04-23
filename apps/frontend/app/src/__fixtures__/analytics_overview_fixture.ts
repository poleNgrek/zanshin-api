import type { AnalyticsOverview } from "@zanshin/types";

export const analytics_overview_fixture: AnalyticsOverview = {
  scope: {
    tournament_id: "d4499989-6f77-4466-9c47-5205156f0ed6",
    division_id: "9583d485-a8f6-4918-b8ca-a89b5838c7ac",
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
  recent_events: [
    {
      event_id: "4726f343-f254-4efa-8130-f9856c699d0f",
      event_type: "match.transitioned",
      aggregate_id: "b06e1842-c8ef-49f6-bbd5-d22f0dd96078",
      occurred_at: "2026-04-21T10:01:00Z",
      payload: { to_state: "ongoing" }
    }
  ],
  insights: {
    throughput_trend: [
      {
        bucket_start: "2026-04-21T10:00:00Z",
        total_events: 4,
        transition_events: 3,
        score_events: 1
      }
    ],
    top_active_matches: [{ match_id: "b06e1842-c8ef-49f6-bbd5-d22f0dd96078", event_count: 4 }],
    actor_role_activity: [{ actor_role: "admin", event_count: 4 }]
  }
};
