import { z } from "zod";

import { dataEnvelopeSchema, idSchema } from "~/lib/schemas/common";

export const gradingResultSchema = z.object({
  id: idSchema,
  competitor_id: idSchema,
  grading_session_id: idSchema,
  target_grade: z.string(),
  final_result: z.string(),
  jitsugi_result: z.string(),
  kata_result: z.string(),
  written_result: z.string(),
  locked_at: z.string().nullable().optional()
});

export const gradingResultListResponseSchema = dataEnvelopeSchema(z.array(gradingResultSchema));

export type GradingResult = z.infer<typeof gradingResultSchema>;
