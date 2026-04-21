import type { z } from "zod";

import { getStoredToken } from "~/lib/auth/tokenStore";
import { getApiBaseUrl } from "~/lib/config";
import { errorEnvelopeSchema } from "~/lib/schemas/common";

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

export async function fetchWithSchema<TSchema extends z.ZodTypeAny>(
  path: string,
  schema: TSchema,
  options: FetchOptions = {}
): Promise<z.infer<TSchema>> {
  const token = options.token || getStoredToken() || undefined;

  const response = await fetch(`${getApiBaseUrl()}${path}`, {
    method: options.method ?? "GET",
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {})
    },
    body: options.body ? JSON.stringify(options.body) : undefined
  });

  const json = await response.json();

  if (!response.ok) {
    const parsedError = errorEnvelopeSchema.safeParse(json);
    if (parsedError.success) {
      throw new ApiError(parsedError.data.error, response.status, parsedError.data.details);
    }
    throw new ApiError("unknown_api_error", response.status, json);
  }

  const parsed = schema.safeParse(json);
  if (!parsed.success) {
    throw new ApiError("invalid_response_schema", response.status, parsed.error.flatten());
  }

  return parsed.data;
}
