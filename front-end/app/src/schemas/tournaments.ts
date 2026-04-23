import { z } from "zod";

import { DataEnvelopeSchema, IdSchema } from "./common";

export const TournamentSchema = z.object({
  id: IdSchema,
  name: z.string(),
  starts_on: z.string().nullable().optional()
});

export const TournamentListResponseSchema = DataEnvelopeSchema(z.array(TournamentSchema));
export const TournamentResponseSchema = DataEnvelopeSchema(TournamentSchema);
