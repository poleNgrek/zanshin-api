import { describe, expect, test } from "bun:test";

import { ApiError, parseSseEventData } from "@zanshin/api";
import { MatchRealtimeSnapshotSchema } from "@zanshin/schemas";

describe("parseSseEventData", () => {
  test("parses match realtime snapshot payload", () => {
    const raw = `event: match_events_snapshot
data: {"tournament_id":"d4499989-6f77-4466-9c47-5205156f0ed6","count":1,"events":[{"id":"4726f343-f254-4efa-8130-f9856c699d0f","event_type":"match.transitioned","aggregate_id":"b06e1842-c8ef-49f6-bbd5-d22f0dd96078","occurred_at":"2026-04-21T10:01:00Z","actor_role":"admin","payload":{"to_state":"ongoing"}}]}
`;

    const payload = parseSseEventData(raw);
    const parsed = MatchRealtimeSnapshotSchema.safeParse(payload);
    expect(parsed.success).toBe(true);
    if (!parsed.success) return;
    expect(parsed.data.events[0]?.event_type).toBe("match.transitioned");
  });

  test("throws ApiError when SSE data line is missing", () => {
    expect(() => parseSseEventData("event: match_events_snapshot\n\n")).toThrow(ApiError);
  });
});
