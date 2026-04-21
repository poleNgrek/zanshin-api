import { beforeEach, describe, expect, test } from "bun:test";

import { getStoredToken, setStoredToken } from "../app/lib/auth/tokenStore";

describe("tokenStore", () => {
  beforeEach(() => {
    localStorage.clear();
  });

  test("stores and reads bearer token", () => {
    setStoredToken("abc123");
    expect(getStoredToken()).toBe("abc123");
  });

  test("removes token when empty string is saved", () => {
    setStoredToken("abc123");
    setStoredToken("");
    expect(getStoredToken()).toBeNull();
  });
});
