import { z } from "zod";

import { DataEnvelopeSchema, IdSchema } from "./common";

export const MatchSchema = z.object({
  id: IdSchema,
  tournament_id: IdSchema,
  division_id: IdSchema,
  aka_competitor_id: IdSchema,
  shiro_competitor_id: IdSchema,
  state: z.string(),
  inserted_at: z.string().nullable().optional()
});

export const MatchListResponseSchema = DataEnvelopeSchema(z.array(MatchSchema));
