import { beforeEach, describe, expect, test } from "bun:test";

import { getStoredToken, setStoredToken } from "../app/lib/auth/tokenStore";

function createMemoryStorage() {
  const store = new Map<string, string>();
  return {
    getItem(key: string) {
      return store.has(key) ? store.get(key)! : null;
    },
    setItem(key: string, value: string) {
      store.set(key, value);
    },
    removeItem(key: string) {
      store.delete(key);
    },
    clear() {
      store.clear();
    }
  };
}

describe("tokenStore", () => {
  beforeEach(() => {
    const localStorage = createMemoryStorage();
    (globalThis as { window?: unknown }).window = { localStorage };
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
