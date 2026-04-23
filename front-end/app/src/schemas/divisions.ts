import { z } from "zod";

import { DataEnvelopeSchema, IdSchema } from "./common";

export const DivisionSchema = z.object({
  id: IdSchema,
  tournament_id: IdSchema,
  name: z.string(),
  format: z.string()
});

export const DivisionListResponseSchema = DataEnvelopeSchema(z.array(DivisionSchema));
export const DivisionResponseSchema = DataEnvelopeSchema(DivisionSchema);
