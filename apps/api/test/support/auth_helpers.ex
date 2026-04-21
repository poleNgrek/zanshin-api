defmodule ZanshinApi.AuthHelpers do
  @moduledoc false

  alias ZanshinApi.Auth.JWT

  def bearer_token_for(role, subject \\ "test-user-1") when is_binary(role) do
    "Bearer " <> JWT.generate_token(subject, role)
  end
end
