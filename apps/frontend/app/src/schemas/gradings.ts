import { z } from "zod";

import { DataEnvelopeSchema, IdSchema } from "./common";

export const GradingResultSchema = z.object({
  id: IdSchema,
  competitor_id: IdSchema,
  grading_session_id: IdSchema,
  target_grade: z.string(),
  final_result: z.string(),
  jitsugi_result: z.string(),
  kata_result: z.string(),
  written_result: z.string(),
  locked_at: z.string().nullable().optional()
});

export const GradingResultListResponseSchema = DataEnvelopeSchema(z.array(GradingResultSchema));
export const GradingResultResponseSchema = DataEnvelopeSchema(GradingResultSchema);
