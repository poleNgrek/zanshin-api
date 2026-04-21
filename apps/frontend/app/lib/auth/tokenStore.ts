const TOKEN_KEY = "zanshin_auth_token";

export function getStoredToken(): string | null {
  if (typeof window === "undefined") return null;
  const value = window.localStorage.getItem(TOKEN_KEY);
  return value && value.length > 0 ? value : null;
}

export function setStoredToken(token: string): void {
  if (typeof window === "undefined") return;
  if (token.trim().length === 0) {
    window.localStorage.removeItem(TOKEN_KEY);
    return;
  }
  window.localStorage.setItem(TOKEN_KEY, token.trim());
}
