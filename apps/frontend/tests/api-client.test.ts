import { describe, expect, mock, test } from "bun:test";

import { ApiError, fetchWithSchema } from "@zanshin/api";
import { TournamentListResponseSchema } from "@zanshin/schemas";

describe("fetchWithSchema", () => {
  test("returns parsed data for valid payload", async () => {
    const fetchMock = mock(() =>
      Promise.resolve(
        new Response(
          JSON.stringify({
            data: [{ id: "d4499989-6f77-4466-9c47-5205156f0ed6", name: "Spring Cup", starts_on: null }]
          }),
          { status: 200 }
        )
      )
    );

    globalThis.fetch = fetchMock as unknown as typeof fetch;

    const response = await fetchWithSchema("/api/v1/tournaments", TournamentListResponseSchema);
    expect(response.data.length).toBe(1);
  });

  test("throws ApiError for invalid schema payload", async () => {
    const fetchMock = mock(() =>
      Promise.resolve(
        new Response(
          JSON.stringify({
            data: [{ id: "not-a-uuid", name: "Spring Cup" }]
          }),
          { status: 200 }
        )
      )
    );

    globalThis.fetch = fetchMock as unknown as typeof fetch;

    await expect(fetchWithSchema("/api/v1/tournaments", TournamentListResponseSchema)).rejects.toBeInstanceOf(
      ApiError
    );
  });
});
