import { z } from "zod";

import { dataEnvelopeSchema, idSchema } from "~/lib/schemas/common";

export const competitorSchema = z.object({
  id: idSchema,
  display_name: z.string(),
  federation_id: z.string().nullable().optional()
});

export const competitorListResponseSchema = dataEnvelopeSchema(z.array(competitorSchema));
export const competitorResponseSchema = dataEnvelopeSchema(competitorSchema);

export type Competitor = z.infer<typeof competitorSchema>;
