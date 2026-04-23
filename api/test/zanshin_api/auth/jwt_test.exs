defmodule ZanshinApi.Auth.JWTTest do
  use ExUnit.Case, async: true

  alias ZanshinApi.Auth.JWT

  test "generate_token/3 and verify_token/1 round trip" do
    token = JWT.generate_token("user-123", "admin")
    assert {:ok, actor} = JWT.verify_token(token)
    assert actor.subject == "user-123"
    assert actor.role == :admin
  end

  test "verify_token/1 rejects malformed token" do
    assert {:error, :invalid_token} = JWT.verify_token("not-a-jwt")
  end
end
