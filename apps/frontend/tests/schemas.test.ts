import { describe, expect, test } from "bun:test";

import { gradingResultListResponseSchema } from "../app/lib/schemas/gradings";
import { matchListResponseSchema } from "../app/lib/schemas/matches";
import { tournamentListResponseSchema } from "../app/lib/schemas/tournaments";

describe("schema parsing", () => {
  test("parses tournament list envelope", () => {
    const payload = {
      data: [{ id: "d4499989-6f77-4466-9c47-5205156f0ed6", name: "Spring Cup", starts_on: null }]
    };

    const result = tournamentListResponseSchema.safeParse(payload);
    expect(result.success).toBe(true);
  });

  test("rejects grading result envelope with missing required fields", () => {
    const payload = {
      data: [{ id: "bad", final_result: "pass" }]
    };

    const result = gradingResultListResponseSchema.safeParse(payload);
    expect(result.success).toBe(false);
  });

  test("parses match list envelope", () => {
    const payload = {
      data: [
        {
          id: "b06e1842-c8ef-49f6-bbd5-d22f0dd96078",
          tournament_id: "d4499989-6f77-4466-9c47-5205156f0ed6",
          division_id: "9583d485-a8f6-4918-b8ca-a89b5838c7ac",
          aka_competitor_id: "22f36686-cc3a-478c-a5a1-7a58faec1e9f",
          shiro_competitor_id: "cad9d450-e970-48f7-abcc-b494a9532474",
          state: "scheduled",
          inserted_at: "2026-04-21T09:44:00Z"
        }
      ]
    };

    const result = matchListResponseSchema.safeParse(payload);
    expect(result.success).toBe(true);
  });
});
