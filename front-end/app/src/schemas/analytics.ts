import { z } from "zod";

import { DataEnvelopeSchema, IdSchema } from "./common";

export const AnalyticsBreakdownItemSchema = z.object({
  event_type: z.string(),
  count: z.number().int().nonnegative()
});

export const AnalyticsStateCountSchema = z.object({
  state: z.string(),
  count: z.number().int().nonnegative()
});

export const AnalyticsRecentEventSchema = z.object({
  event_id: IdSchema,
  event_type: z.string(),
  aggregate_id: IdSchema,
  occurred_at: z.string(),
  payload: z.record(z.string(), z.unknown())
});

export const AnalyticsOverviewSchema = z.object({
  scope: z.object({
    tournament_id: IdSchema,
    division_id: IdSchema.nullable().optional(),
    from: z.string().nullable().optional(),
    to: z.string().nullable().optional()
  }),
  data_source: z.string(),
  summary: z.object({
    kpis: z.object({
      total_events: z.number().int().nonnegative(),
      transition_events: z.number().int().nonnegative(),
      score_events: z.number().int().nonnegative()
    }),
    event_type_breakdown: z.array(AnalyticsBreakdownItemSchema)
  }),
  state_overview: z.object({
    state_counts: z.array(AnalyticsStateCountSchema)
  }),
  recent_events: z.array(AnalyticsRecentEventSchema),
  insights: z.object({
    throughput_trend: z.array(
      z.object({
        bucket_start: z.string(),
        total_events: z.number().int().nonnegative(),
        transition_events: z.number().int().nonnegative(),
        score_events: z.number().int().nonnegative()
      })
    ),
    top_active_matches: z.array(
      z.object({
        match_id: IdSchema,
        event_count: z.number().int().nonnegative()
      })
    ),
    actor_role_activity: z.array(
      z.object({
        actor_role: z.string(),
        event_count: z.number().int().nonnegative()
      })
    )
  })
});

export const AnalyticsOverviewResponseSchema = DataEnvelopeSchema(AnalyticsOverviewSchema);
