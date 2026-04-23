import { describe, expect, test } from "bun:test";

import {
  applyAdminCompetitorEvents,
  applyAdminGradingResultEvents,
  applyAdminSessionEvents,
  applyAdminTournamentEvents,
  applyEventsToAnalyticsOverview,
  applyMatchRealtimeEvents
} from "@zanshin/utils/realtime_updates";
import type { AnalyticsOverview, Match, MatchRealtimeEvent } from "@zanshin/types";

describe("applyMatchRealtimeEvents", () => {
  test("updates match state from transition event", () => {
    const matches: Match[] = [
      {
        id: "b06e1842-c8ef-49f6-bbd5-d22f0dd96078",
        tournament_id: "d4499989-6f77-4466-9c47-5205156f0ed6",
        division_id: "9583d485-a8f6-4918-b8ca-a89b5838c7ac",
        aka_competitor_id: "22f36686-cc3a-478c-a5a1-7a58faec1e9f",
        shiro_competitor_id: "cad9d450-e970-48f7-abcc-b494a9532474",
        state: "ready",
        inserted_at: "2026-04-21T09:44:00Z"
      }
    ];

    const events: MatchRealtimeEvent[] = [
      {
        id: "4726f343-f254-4efa-8130-f9856c699d0f",
        event_type: "match.transitioned",
        aggregate_id: "b06e1842-c8ef-49f6-bbd5-d22f0dd96078",
        occurred_at: "2026-04-21T10:01:00Z",
        actor_role: "admin",
        payload: {
          match_id: "b06e1842-c8ef-49f6-bbd5-d22f0dd96078",
          to_state: "ongoing"
        }
      }
    ];

    const next = applyMatchRealtimeEvents(matches, events);
    expect(next[0]?.state).toBe("ongoing");
  });
});

describe("applyEventsToAnalyticsOverview", () => {
  test("increments KPIs and state overview for in-scope events", () => {
    const overview: AnalyticsOverview = {
      scope: {
        tournament_id: "d4499989-6f77-4466-9c47-5205156f0ed6",
        division_id: null,
        from: null,
        to: null
      },
      data_source: "neo4j",
      summary: {
        kpis: {
          total_events: 3,
          transition_events: 2,
          score_events: 1
        },
        event_type_breakdown: [
          { event_type: "match.transitioned", count: 2 },
          { event_type: "match.score_recorded", count: 1 }
        ]
      },
      state_overview: {
        state_counts: [{ state: "ongoing", count: 1 }]
      },
      insights: {
        throughput_trend: [
          {
            bucket_start: "2026-04-21T10:00:00.000Z",
            total_events: 3,
            transition_events: 2,
            score_events: 1
          }
        ],
        top_active_matches: [
          {
            match_id: "b06e1842-c8ef-49f6-bbd5-d22f0dd96078",
            event_count: 3
          }
        ],
        actor_role_activity: [{ actor_role: "admin", event_count: 3 }]
      },
      recent_events: []
    };

    const events: MatchRealtimeEvent[] = [
      {
        id: "3726f343-f254-4efa-8130-f9856c699d0f",
        event_type: "match.transitioned",
        aggregate_id: "b06e1842-c8ef-49f6-bbd5-d22f0dd96078",
        occurred_at: "2026-04-21T10:15:00Z",
        actor_role: "admin",
        payload: {
          division_id: "9583d485-a8f6-4918-b8ca-a89b5838c7ac",
          to_state: "completed"
        }
      }
    ];

    const next = applyEventsToAnalyticsOverview(overview, events, {
      divisionId: "",
      fromIso: "",
      toIso: ""
    });

    expect(next.summary.kpis.total_events).toBe(4);
    expect(next.summary.kpis.transition_events).toBe(3);
    expect(next.state_overview.state_counts.find((item) => item.state === "completed")?.count).toBe(1);
    expect(next.recent_events.length).toBe(1);
  });
});

describe("admin reducer updates", () => {
  test("adds created tournament and competitor from admin events", () => {
    const tournaments = applyAdminTournamentEvents([], [
      {
        event: "admin_tournament_created",
        payload: {
          tournament_id: "d4499989-6f77-4466-9c47-5205156f0ed6",
          name: "Realtime Cup"
        }
      }
    ]);

    const competitors = applyAdminCompetitorEvents([], [
      {
        event: "admin_competitor_created",
        payload: {
          competitor_id: "22f36686-cc3a-478c-a5a1-7a58faec1e9f",
          display_name: "Aka Fighter"
        }
      }
    ]);

    expect(tournaments[0]?.name).toBe("Realtime Cup");
    expect(competitors[0]?.display_name).toBe("Aka Fighter");
  });

  test("adds grading sessions scoped to selected tournament", () => {
    const next = applyAdminSessionEvents(
      [],
      [
        {
          event: "admin_grading_session_created",
          payload: {
            tournament_id: "d4499989-6f77-4466-9c47-5205156f0ed6",
            grading_session_id: "9583d485-a8f6-4918-b8ca-a89b5838c7ac",
            session_name: "Evening Shinsa"
          }
        }
      ],
      "d4499989-6f77-4466-9c47-5205156f0ed6"
    );

    expect(next.length).toBe(1);
    expect(next[0]?.name).toBe("Evening Shinsa");
  });

  test("updates grading result in-memory and flags reload for create event", () => {
    const baseResults = [
      {
        id: "b06e1842-c8ef-49f6-bbd5-d22f0dd96078",
        competitor_id: "22f36686-cc3a-478c-a5a1-7a58faec1e9f",
        grading_session_id: "9583d485-a8f6-4918-b8ca-a89b5838c7ac",
        target_grade: "4dan",
        final_result: "pending",
        jitsugi_result: "pass",
        kata_result: "pending",
        written_result: "pending",
        locked_at: null
      }
    ];

    const computed = applyAdminGradingResultEvents(
      baseResults,
      [
        {
          event: "admin_grading_result_computed",
          payload: {
            grading_session_id: "9583d485-a8f6-4918-b8ca-a89b5838c7ac",
            grading_result_id: "b06e1842-c8ef-49f6-bbd5-d22f0dd96078",
            final_result: "pass"
          }
        }
      ],
      "9583d485-a8f6-4918-b8ca-a89b5838c7ac"
    );

    const created = applyAdminGradingResultEvents(
      baseResults,
      [
        {
          event: "admin_grading_result_created",
          payload: {
            grading_session_id: "9583d485-a8f6-4918-b8ca-a89b5838c7ac",
            grading_result_id: "c99e1842-c8ef-49f6-bbd5-d22f0dd96079"
          }
        }
      ],
      "9583d485-a8f6-4918-b8ca-a89b5838c7ac"
    );

    expect(computed.results[0]?.final_result).toBe("pass");
    expect(computed.shouldReload).toBe(false);
    expect(created.shouldReload).toBe(true);
  });
});
