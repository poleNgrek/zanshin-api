import { z } from "zod";

import { DataEnvelopeSchema, IdSchema } from "./common";

export const CompetitorSchema = z.object({
  id: IdSchema,
  display_name: z.string(),
  federation_id: z.string().nullable().optional()
});

export const CompetitorListResponseSchema = DataEnvelopeSchema(z.array(CompetitorSchema));
export const CompetitorResponseSchema = DataEnvelopeSchema(CompetitorSchema);
