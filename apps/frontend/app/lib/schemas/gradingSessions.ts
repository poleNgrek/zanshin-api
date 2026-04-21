import { z } from "zod";

import { dataEnvelopeSchema, idSchema } from "~/lib/schemas/common";

export const gradingSessionSchema = z.object({
  id: idSchema,
  tournament_id: idSchema,
  name: z.string(),
  held_on: z.string().nullable().optional(),
  written_required: z.boolean().optional()
});

export const gradingSessionListResponseSchema = dataEnvelopeSchema(z.array(gradingSessionSchema));
export const gradingSessionResponseSchema = dataEnvelopeSchema(gradingSessionSchema);

export type GradingSession = z.infer<typeof gradingSessionSchema>;
