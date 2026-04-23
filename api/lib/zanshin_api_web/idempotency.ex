defmodule ZanshinApiWeb.Idempotency do
  @moduledoc """
  Executes command handlers under idempotency key protection.
  """

  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn

  alias ZanshinApi.Idempotency

  @idempotency_header "idempotency-key"

  def run(conn, params, handler) when is_function(handler, 0) do
    endpoint = conn.request_path

    with {:ok, key} <- fetch_idempotency_key(conn),
         {:ok, actor_subject} <- fetch_actor_subject(conn),
         {:ok, request_fingerprint} <- fingerprint(conn.method, endpoint, params) do
      case Idempotency.get(key, endpoint, actor_subject) do
        nil ->
          reserve_and_execute(conn, key, endpoint, actor_subject, request_fingerprint, handler)

        _request_key ->
          replay_existing(conn, key, endpoint, actor_subject, request_fingerprint)
      end
    else
      {:error, :idempotency_key_required} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "idempotency_key_required"})

      {:error, :missing_actor_subject} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "unauthorized"})
    end
  end

  defp reserve_and_execute(conn, key, endpoint, actor_subject, request_fingerprint, handler) do
    case Idempotency.reserve(%{
           key: key,
           endpoint: endpoint,
           actor_subject: actor_subject,
           request_fingerprint: request_fingerprint
         }) do
      {:ok, request_key} ->
        response_conn = handler.()
        persist_response(request_key, response_conn)
        response_conn

      {:error, %Ecto.Changeset{}} ->
        replay_existing(conn, key, endpoint, actor_subject, request_fingerprint)
    end
  end

  defp fetch_idempotency_key(conn) do
    case get_req_header(conn, @idempotency_header) do
      [value] ->
        trimmed_value = String.trim(value)

        if trimmed_value == "" do
          {:error, :idempotency_key_required}
        else
          {:ok, trimmed_value}
        end

      _ ->
        {:error, :idempotency_key_required}
    end
  end

  defp fetch_actor_subject(conn) do
    case conn.assigns[:current_actor] do
      %{subject: subject} when is_binary(subject) and byte_size(subject) > 0 -> {:ok, subject}
      _ -> {:error, :missing_actor_subject}
    end
  end

  defp fingerprint(http_method, endpoint, params) do
    normalized_payload = normalize_value(params)
    serialized = :erlang.term_to_binary({http_method, endpoint, normalized_payload})
    {:ok, Base.encode16(:crypto.hash(:sha256, serialized), case: :lower)}
  end

  defp normalize_value(value) when is_map(value) do
    value
    |> Enum.map(fn {key, nested_value} -> {to_string(key), normalize_value(nested_value)} end)
    |> Enum.sort_by(fn {key, _} -> key end)
  end

  defp normalize_value(value) when is_list(value), do: Enum.map(value, &normalize_value/1)
  defp normalize_value(value), do: value

  defp replay_existing(conn, key, endpoint, actor_subject, request_fingerprint) do
    case Idempotency.get(key, endpoint, actor_subject) do
      nil ->
        conn
        |> put_status(:conflict)
        |> json(%{error: "idempotency_request_in_progress"})

      existing_request ->
        cond do
          existing_request.request_fingerprint != request_fingerprint ->
            conn
            |> put_status(:conflict)
            |> json(%{error: "idempotency_key_reused_with_different_payload"})

          is_nil(existing_request.completed_at) ->
            conn
            |> put_status(:conflict)
            |> json(%{error: "idempotency_request_in_progress"})

          true ->
            _ = Idempotency.mark_replayed(existing_request)

            conn
            |> put_resp_header("x-idempotent-replayed", "true")
            |> put_status(existing_request.response_status || 200)
            |> json(existing_request.response_body || %{})
        end
    end
  end

  defp persist_response(request_key, response_conn) do
    status = response_conn.status || 200
    response_body = decode_response_body(response_conn.resp_body)
    _ = Idempotency.complete(request_key, status, response_body)
    :ok
  end

  defp decode_response_body(nil), do: %{}

  defp decode_response_body(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} when is_map(decoded) -> decoded
      _ -> %{"raw_response" => body}
    end
  end
end
