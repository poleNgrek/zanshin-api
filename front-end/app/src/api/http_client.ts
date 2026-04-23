import type { z } from "zod";

import { get_stored_token } from "@zanshin/providers";
import { ErrorEnvelopeSchema, MatchRealtimeSnapshotSchema } from "@zanshin/schemas";
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

type MatchRealtimeSnapshotOptions = {
  tournament_id: string;
  since_id?: string;
  limit?: number;
  token?: string;
};

export async function fetch_with_schema<TSchema extends z.ZodTypeAny>(
  path: string,
  schema: TSchema,
  options: FetchOptions = {}
): Promise<z.infer<TSchema>> {
  const token = options.token || get_stored_token() || undefined;

  let response: Response;

  try {
    response = await fetch(`${get_api_base_url()}${path}`, {
      method: options.method ?? "GET",
      headers: {
        "Content-Type": "application/json",
        ...(token ? { Authorization: `Bearer ${token}` } : {})
      },
      body: options.body ? JSON.stringify(options.body) : undefined
    });
  } catch (error) {
    throw new ApiError("api_unreachable", 0, error);
  }

  let json: unknown;
  try {
    json = await response.json();
  } catch {
    throw new ApiError("invalid_json_response", response.status);
  }

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

export async function fetch_match_events_snapshot(
  options: MatchRealtimeSnapshotOptions
): Promise<z.infer<typeof MatchRealtimeSnapshotSchema>> {
  const token = options.token || get_stored_token() || undefined;
  const query = new URLSearchParams({ tournament_id: options.tournament_id });

  if (options.since_id) {
    query.set("since_id", options.since_id);
  }

  if (typeof options.limit === "number") {
    query.set("limit", String(options.limit));
  }

  const response = await fetch(
    `${get_api_base_url()}/api/v1/realtime/matches/stream?${query.toString()}`,
    {
      method: "GET",
      headers: {
        Accept: "text/event-stream",
        ...(token ? { Authorization: `Bearer ${token}` } : {})
      }
    }
  );

  const body = await response.text();

  if (!response.ok) {
    try {
      const parsed_error = ErrorEnvelopeSchema.safeParse(JSON.parse(body));
      if (parsed_error.success) {
        throw new ApiError(parsed_error.data.error, response.status, parsed_error.data.details);
      }
    } catch {
      // Ignore JSON parse failures for non-JSON responses.
    }

    throw new ApiError("unknown_api_error", response.status, body);
  }

  const event_data = parse_sse_event_data(body);
  const parsed_payload = MatchRealtimeSnapshotSchema.safeParse(event_data);

  if (!parsed_payload.success) {
    throw new ApiError("invalid_response_schema", response.status, parsed_payload.error.flatten());
  }

  return parsed_payload.data;
}

export function parse_sse_event_data(raw_body: string): unknown {
  const data_line = raw_body
    .split("\n")
    .find((line) => line.startsWith("data:"));

  if (!data_line) {
    throw new ApiError("invalid_response_schema", 200, "missing_sse_data_line");
  }

  const payload = data_line.slice(5).trim();

  try {
    return JSON.parse(payload);
  } catch {
    throw new ApiError("invalid_response_schema", 200, "invalid_sse_json");
  }
}
