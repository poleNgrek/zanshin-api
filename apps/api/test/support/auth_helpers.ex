defmodule ZanshinApi.AuthHelpers do
  @moduledoc false

  alias ZanshinApi.TestOAuth

  def bearer_token_for(role, subject \\ "test-user-1") when is_binary(role) do
    "Bearer " <> TestOAuth.sign_token(role, subject)
  end
end
