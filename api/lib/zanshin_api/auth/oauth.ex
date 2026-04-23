defmodule ZanshinApi.Auth.OAuth do
  @moduledoc """
  OAuth/JWKS token verification for API bearer tokens.
  """

  @roles ~w(admin timekeeper shinpan)
  @cache_key {__MODULE__, :jwks}

  def verify_token(token) when is_binary(token) do
    with {:ok, header} <- peek_header(token),
         {:ok, kid} <- extract_kid(header),
         {:ok, jwk} <- find_jwk(kid),
         {true, %JOSE.JWT{fields: claims}, _} <- JOSE.JWT.verify_strict(jwk, ["RS256"], token),
         :ok <- validate_claims(claims),
         {:ok, role} <- extract_role(claims) do
      {:ok, %{subject: claims["sub"], role: String.to_atom(role), claims: claims}}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, :invalid_token}
    end
  rescue
    _ -> {:error, :invalid_token}
  end

  defp validate_claims(%{"sub" => sub, "iss" => iss, "exp" => exp, "aud" => aud})
       when is_binary(sub) and is_binary(iss) and is_integer(exp) do
    expected_issuer = config()[:issuer]
    expected_audience = config()[:audience]

    cond do
      iss != expected_issuer ->
        {:error, :invalid_issuer}

      exp <= System.system_time(:second) ->
        {:error, :token_expired}

      not audience_match?(aud, expected_audience) ->
        {:error, :invalid_audience}

      true ->
        :ok
    end
  end

  defp validate_claims(_), do: {:error, :invalid_claims}

  defp extract_role(%{"role" => role}) when is_binary(role) and role in @roles, do: {:ok, role}

  defp extract_role(%{"roles" => [role | _]}) when is_binary(role) and role in @roles,
    do: {:ok, role}

  defp extract_role(_), do: {:error, :invalid_role}

  defp audience_match?(aud, expected) when is_binary(aud), do: aud == expected
  defp audience_match?(aud, expected) when is_list(aud), do: expected in aud
  defp audience_match?(_, _), do: false

  defp peek_header(token) do
    case JOSE.JWT.peek_protected(token) do
      %JOSE.JWS{fields: fields} when is_map(fields) -> {:ok, fields}
      map when is_map(map) -> {:ok, map}
      _ -> {:error, :invalid_token_header}
    end
  end

  defp extract_kid(%{"kid" => kid}) when is_binary(kid), do: {:ok, kid}
  defp extract_kid(%{kid: kid}) when is_binary(kid), do: {:ok, kid}
  defp extract_kid(_), do: {:ok, nil}

  defp find_jwk(kid) do
    with {:ok, keys} <- load_jwks_keys(),
         jwk_value <- select_jwk(keys, kid),
         {:ok, jwk} <- to_jwk(jwk_value) do
      {:ok, jwk}
    else
      nil -> {:error, :jwks_key_not_found}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :invalid_jwks}
    end
  end

  defp select_jwk([single], nil), do: single
  defp select_jwk(keys, nil), do: Enum.find(keys, &is_map/1)
  defp select_jwk(keys, kid), do: Enum.find(keys, &(jwk_kid(&1) == kid))

  defp jwk_kid(%JOSE.JWK{fields: fields}) when is_map(fields), do: fields["kid"] || fields[:kid]
  defp jwk_kid(map), do: map["kid"] || map[:kid]

  defp load_jwks_keys do
    with {:ok, jwks} <- load_jwks() do
      case jwks do
        %{"keys" => keys} when is_list(keys) -> {:ok, keys}
        %{keys: keys} when is_list(keys) -> {:ok, keys}
        _ -> {:error, :invalid_jwks}
      end
    end
  end

  defp to_jwk(%JOSE.JWK{} = jwk), do: {:ok, jwk}

  defp to_jwk(map) when is_map(map) do
    {:ok, JOSE.JWK.from_map(map)}
  rescue
    _ -> {:error, :invalid_jwks}
  end

  defp load_jwks do
    case config()[:jwks] do
      jwks when is_map(jwks) ->
        {:ok, jwks}

      _ ->
        ttl = config()[:jwks_cache_ttl_seconds] || 300
        now = System.system_time(:second)

        case :persistent_term.get(@cache_key, nil) do
          %{expires_at: expires_at, jwks: jwks} when expires_at > now ->
            {:ok, jwks}

          _ ->
            with {:ok, jwks} <- source_jwks() do
              :persistent_term.put(@cache_key, %{expires_at: now + ttl, jwks: jwks})
              {:ok, jwks}
            end
        end
    end
  end

  defp source_jwks do
    case config()[:jwks] do
      jwks when is_map(jwks) ->
        {:ok, jwks}

      _ ->
        fetch_jwks_from_url(config()[:jwks_url])
    end
  end

  defp fetch_jwks_from_url(nil), do: {:error, :jwks_unavailable}

  defp fetch_jwks_from_url(url) do
    inets_started = ensure_started(:inets)
    ssl_started = ensure_started(:ssl)

    with :ok <- inets_started,
         :ok <- ssl_started,
         {:ok, {{_, 200, _}, _headers, body}} <-
           :httpc.request(:get, {to_charlist(url), []}, [], []),
         {:ok, decoded} <- Jason.decode(to_string(body)) do
      {:ok, decoded}
    else
      _ -> {:error, :jwks_fetch_failed}
    end
  end

  defp ensure_started(app) do
    case Application.ensure_all_started(app) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
      {:error, _} = err -> err
    end
  end

  defp config do
    Application.fetch_env!(:zanshin_api, __MODULE__)
  end
end
