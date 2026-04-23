import { z } from "zod";

export const IdSchema = z.string().uuid();

export const GenericEntitySchema = z.record(z.string(), z.unknown());

export const DataEnvelopeSchema = <T extends z.ZodTypeAny>(schema: T) =>
  z.object({
    data: schema
  });

export const ErrorEnvelopeSchema = z.object({
  error: z.string(),
  details: z.unknown().optional()
});
