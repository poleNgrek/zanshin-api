const DEFAULT_API_BASE_URL = "http://localhost:4000";

export function get_api_base_url(): string {
  if (typeof process !== "undefined" && process.env.API_BASE_URL) {
    return process.env.API_BASE_URL;
  }

  if (typeof window !== "undefined") {
    const from_window = (window as unknown as { __ZANSHIN_API_BASE_URL?: string }).__ZANSHIN_API_BASE_URL;
    if (from_window && from_window.length > 0) {
      return from_window;
    }
  }

  return DEFAULT_API_BASE_URL;
}
