import { describe, expect, test } from "bun:test";

import { gradingResultListResponseSchema } from "../app/lib/schemas/gradings";
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
});
