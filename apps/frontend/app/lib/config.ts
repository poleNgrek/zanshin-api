const DEFAULT_API_BASE_URL = "http://localhost:4000";

export function getApiBaseUrl(): string {
  if (typeof process !== "undefined" && process.env.API_BASE_URL) {
    return process.env.API_BASE_URL;
  }

  if (typeof window !== "undefined") {
    const fromWindow = (window as unknown as { __ZANSHIN_API_BASE_URL?: string }).__ZANSHIN_API_BASE_URL;
    if (fromWindow && fromWindow.length > 0) {
      return fromWindow;
    }
  }

  return DEFAULT_API_BASE_URL;
}
