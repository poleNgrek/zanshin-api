import { z } from "zod";

export const idSchema = z.string().uuid();

export const genericEntitySchema = z.record(z.unknown());

export const dataEnvelopeSchema = <T extends z.ZodTypeAny>(schema: T) =>
  z.object({
    data: schema
  });

export const errorEnvelopeSchema = z.object({
  error: z.string(),
  details: z.unknown().optional()
});
