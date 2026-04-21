import { z } from "zod";

import { dataEnvelopeSchema, idSchema } from "~/lib/schemas/common";

export const divisionSchema = z.object({
  id: idSchema,
  tournament_id: idSchema,
  name: z.string(),
  format: z.string()
});

export const divisionListResponseSchema = dataEnvelopeSchema(z.array(divisionSchema));
export const divisionResponseSchema = dataEnvelopeSchema(divisionSchema);

export type Division = z.infer<typeof divisionSchema>;
