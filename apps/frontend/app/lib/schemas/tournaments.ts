import { z } from "zod";

import { dataEnvelopeSchema, idSchema } from "~/lib/schemas/common";

export const tournamentSchema = z.object({
  id: idSchema,
  name: z.string(),
  starts_on: z.string().nullable().optional()
});

export const tournamentListResponseSchema = dataEnvelopeSchema(z.array(tournamentSchema));
export const tournamentResponseSchema = dataEnvelopeSchema(tournamentSchema);

export type Tournament = z.infer<typeof tournamentSchema>;
