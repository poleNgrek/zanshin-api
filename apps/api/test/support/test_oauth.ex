defmodule ZanshinApi.TestOAuth do
  @moduledoc false

  @cache_key {__MODULE__, :private_jwk}
  @kid "test-key-1"

  def setup! do
    private_jwk =
      case :persistent_term.get(@cache_key, nil) do
        nil ->
          generated_jwk =
            JOSE.JWK.generate_key({:rsa, 2048, 65_537}) |> JOSE.JWK.merge(%{"kid" => @kid})

          :persistent_term.put(@cache_key, generated_jwk)
          generated_jwk

        existing_jwk ->
          existing_jwk
      end

    public_jwk = JOSE.JWK.to_public(private_jwk)

    Application.put_env(:zanshin_api, ZanshinApi.Auth, mode: :oauth_jwks)

    Application.put_env(:zanshin_api, ZanshinApi.Auth.OAuth,
      issuer: "https://auth.test.local",
      audience: "zanshin-api",
      jwks: %{"keys" => [public_jwk]},
      jwks_url: nil,
      jwks_cache_ttl_seconds: 300
    )

    :ok
  end

  def sign_token(role, subject \\ "test-user-1", ttl_seconds \\ 3600) when is_binary(role) do
    now = System.system_time(:second)
    private_jwk = :persistent_term.get(@cache_key)

    claims = %{
      "sub" => subject,
      "role" => role,
      "iss" => "https://auth.test.local",
      "aud" => "zanshin-api",
      "iat" => now,
      "exp" => now + ttl_seconds
    }

    {_, token} =
      JOSE.JWT.sign(private_jwk, %{"alg" => "RS256", "kid" => @kid}, claims) |> JOSE.JWS.compact()

    token
  end
end
