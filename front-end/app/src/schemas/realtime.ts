import { z } from "zod";

import { IdSchema } from "./common";

export const MatchRealtimeEventSchema = z.object({
  id: IdSchema,
  event_type: z.string().min(1),
  aggregate_id: IdSchema,
  occurred_at: z.string().datetime(),
  actor_role: z.string().min(1).nullable().optional(),
  payload: z.record(z.string(), z.unknown())
});

export const MatchRealtimeSnapshotSchema = z.object({
  tournament_id: IdSchema,
  count: z.number().int().min(0),
  events: z.array(MatchRealtimeEventSchema)
});
