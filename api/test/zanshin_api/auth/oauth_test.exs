defmodule ZanshinApi.Auth.OAuthTest do
  use ExUnit.Case, async: true

  alias ZanshinApi.Auth.OAuth
  alias ZanshinApi.TestOAuth

  test "verify_token/1 validates RS256 token against configured JWKS" do
    token = TestOAuth.sign_token("admin", "oauth-user")
    assert {:ok, actor} = OAuth.verify_token(token)
    assert actor.subject == "oauth-user"
    assert actor.role == :admin
  end

  test "verify_token/1 rejects malformed token" do
    assert {:error, :invalid_token} = OAuth.verify_token("broken-token")
  end
end
