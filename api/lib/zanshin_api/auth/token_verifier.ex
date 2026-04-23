defmodule ZanshinApi.Auth.TokenVerifier do
  @moduledoc """
  Delegates token verification to the configured auth mode.
  """

  alias ZanshinApi.Auth.{JWT, OAuth}

  def verify_token(token) do
    case auth_mode() do
      :legacy_hs256 -> JWT.verify_token(token)
      _ -> OAuth.verify_token(token)
    end
  end

  defp auth_mode do
    Application.fetch_env!(:zanshin_api, ZanshinApi.Auth)[:mode]
  end
end
