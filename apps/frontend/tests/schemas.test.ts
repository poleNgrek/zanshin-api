import { describe, expect, test } from "bun:test";

import {
  AnalyticsOverviewResponseSchema,
  GradingResultListResponseSchema,
  MatchListResponseSchema,
  TournamentListResponseSchema
} from "@zanshin/schemas";

describe("schema parsing", () => {
  test("parses tournament list envelope", () => {
    const payload = {
      data: [{ id: "d4499989-6f77-4466-9c47-5205156f0ed6", name: "Spring Cup", starts_on: null }]
    };

    const result = TournamentListResponseSchema.safeParse(payload);
    expect(result.success).toBe(true);
  });

  test("rejects grading result envelope with missing required fields", () => {
    const payload = {
      data: [{ id: "bad", final_result: "pass" }]
    };

    const result = GradingResultListResponseSchema.safeParse(payload);
    expect(result.success).toBe(false);
  });

  test("parses match list envelope", () => {
    const payload = {
      data: [
        {
          id: "b06e1842-c8ef-49f6-bbd5-d22f0dd96078",
          tournament_id: "d4499989-6f77-4466-9c47-5205156f0ed6",
          division_id: "9583d485-a8f6-4918-b8ca-a89b5838c7ac",
          aka_competitor_id: "22f36686-cc3a-478c-a5a1-7a58faec1e9f",
          shiro_competitor_id: "cad9d450-e970-48f7-abcc-b494a9532474",
          state: "scheduled",
          inserted_at: "2026-04-21T09:44:00Z"
        }
      ]
    };

    const result = MatchListResponseSchema.safeParse(payload);
    expect(result.success).toBe(true);
  });

  test("parses analytics dashboard overview envelope", () => {
    const payload = {
      data: {
        scope: {
          tournament_id: "d4499989-6f77-4466-9c47-5205156f0ed6",
          division_id: "9583d485-a8f6-4918-b8ca-a89b5838c7ac",
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
              bucket_start: "2026-04-21T10:00:00Z",
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
        recent_events: [
          {
            event_id: "4726f343-f254-4efa-8130-f9856c699d0f",
            event_type: "match.transitioned",
            aggregate_id: "b06e1842-c8ef-49f6-bbd5-d22f0dd96078",
            occurred_at: "2026-04-21T10:01:00Z",
            payload: { to_state: "ongoing" }
          }
        ]
      }
    };

    const result = AnalyticsOverviewResponseSchema.safeParse(payload);
    expect(result.success).toBe(true);
  });
});
