import { z } from "zod";

import { DataEnvelopeSchema, IdSchema } from "./common";

export const GradingSessionSchema = z.object({
  id: IdSchema,
  tournament_id: IdSchema,
  name: z.string(),
  held_on: z.string().nullable().optional(),
  written_required: z.boolean().optional()
});

export const GradingSessionListResponseSchema = DataEnvelopeSchema(z.array(GradingSessionSchema));
export const GradingSessionResponseSchema = DataEnvelopeSchema(GradingSessionSchema);
