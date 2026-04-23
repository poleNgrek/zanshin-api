import { z } from "zod";

import { dataEnvelopeSchema, idSchema } from "~/lib/schemas/common";

export const matchSchema = z.object({
  id: idSchema,
  tournament_id: idSchema,
  division_id: idSchema,
  aka_competitor_id: idSchema,
  shiro_competitor_id: idSchema,
  state: z.string(),
  inserted_at: z.string().nullable().optional()
});

export const matchListResponseSchema = dataEnvelopeSchema(z.array(matchSchema));

export type Match = z.infer<typeof matchSchema>;
