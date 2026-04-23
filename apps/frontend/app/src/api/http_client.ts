import type { z } from "zod";

import { get_stored_token } from "@zanshin/providers";
import { ErrorEnvelopeSchema } from "@zanshin/schemas";
import { get_api_base_url } from "@zanshin/utils";

export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
    public details?: unknown
  ) {
    super(message);
    this.name = "ApiError";
  }
}

type FetchOptions = {
  method?: string;
  token?: string;
  body?: unknown;
};

export async function fetch_with_schema<TSchema extends z.ZodTypeAny>(
  path: string,
  schema: TSchema,
  options: FetchOptions = {}
): Promise<z.infer<TSchema>> {
  const token = options.token || get_stored_token() || undefined;

  const response = await fetch(`${get_api_base_url()}${path}`, {
    method: options.method ?? "GET",
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {})
    },
    body: options.body ? JSON.stringify(options.body) : undefined
  });

  const json = await response.json();

  if (!response.ok) {
    const parsed_error = ErrorEnvelopeSchema.safeParse(json);
    if (parsed_error.success) {
      throw new ApiError(parsed_error.data.error, response.status, parsed_error.data.details);
    }
    throw new ApiError("unknown_api_error", response.status, json);
  }

  const parsed = schema.safeParse(json);
  if (!parsed.success) {
    throw new ApiError("invalid_response_schema", response.status, parsed.error.flatten());
  }

  return parsed.data;
}
