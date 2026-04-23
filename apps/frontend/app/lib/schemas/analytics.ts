import { z } from "zod";

import { dataEnvelopeSchema, idSchema } from "~/lib/schemas/common";

export const analyticsBreakdownItemSchema = z.object({
  event_type: z.string(),
  count: z.number().int().nonnegative()
});

export const analyticsStateCountSchema = z.object({
  state: z.string(),
  count: z.number().int().nonnegative()
});

export const analyticsRecentEventSchema = z.object({
  event_id: idSchema,
  event_type: z.string(),
  aggregate_id: idSchema,
  occurred_at: z.string(),
  payload: z.record(z.string(), z.unknown())
});

export const analyticsOverviewSchema = z.object({
  scope: z.object({
    tournament_id: idSchema,
    division_id: idSchema.nullable().optional(),
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
    event_type_breakdown: z.array(analyticsBreakdownItemSchema)
  }),
  state_overview: z.object({
    state_counts: z.array(analyticsStateCountSchema)
  }),
  recent_events: z.array(analyticsRecentEventSchema),
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
        match_id: idSchema,
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

export const analyticsOverviewResponseSchema = dataEnvelopeSchema(analyticsOverviewSchema);

export type AnalyticsOverview = z.infer<typeof analyticsOverviewSchema>;
