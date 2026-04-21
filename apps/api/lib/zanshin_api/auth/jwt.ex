defmodule ZanshinApi.Auth.JWT do
  @moduledoc """
  Minimal JWT signing and verification for phase 2 auth baseline.
  """

  @roles ~w(admin timekeeper shinpan)

  def generate_token(subject, role, ttl_seconds \\ 3600)
      when is_binary(subject) and is_binary(role) and is_integer(ttl_seconds) do
    now = System.system_time(:second)
    secret = secret()
    issuer = issuer()

    claims = %{
      "sub" => subject,
      "role" => role,
      "iss" => issuer,
      "iat" => now,
      "exp" => now + ttl_seconds
    }

    jwk = JOSE.JWK.from_oct(secret)
    {_, token} = JOSE.JWT.sign(jwk, %{"alg" => "HS256"}, claims) |> JOSE.JWS.compact()
    token
  end

  def verify_token(token) when is_binary(token) do
    jwk = JOSE.JWK.from_oct(secret())

    case JOSE.JWT.verify_strict(jwk, ["HS256"], token) do
      {true, %JOSE.JWT{fields: fields}, _signature} ->
        validate_claims(fields)

      _ ->
        {:error, :invalid_token}
    end
  rescue
    _ -> {:error, :invalid_token}
  end

  defp validate_claims(%{"sub" => sub, "role" => role, "iss" => iss, "exp" => exp} = claims)
       when is_binary(sub) and is_binary(role) and is_binary(iss) and is_integer(exp) do
    cond do
      iss != issuer() ->
        {:error, :invalid_issuer}

      exp <= System.system_time(:second) ->
        {:error, :token_expired}

      role not in @roles ->
        {:error, :invalid_role}

      true ->
        {:ok, %{subject: sub, role: String.to_existing_atom(role), claims: claims}}
    end
  end

  defp validate_claims(_), do: {:error, :invalid_claims}

  defp secret do
    Application.fetch_env!(:zanshin_api, __MODULE__)[:secret]
  end

  defp issuer do
    Application.fetch_env!(:zanshin_api, __MODULE__)[:issuer]
  end
end
