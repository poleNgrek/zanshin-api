defmodule ZanshinApiWeb.Pagination do
  @moduledoc false

  @default_limit 50
  @max_limit 200

  def json_paginated(conn, params, entries, serializer_fun) when is_list(entries) do
    with {:ok, pagination} <- parse(params) do
      paged_entries = entries |> Enum.drop(pagination.offset) |> Enum.take(pagination.limit)
      data = Enum.map(paged_entries, serializer_fun)
      total = length(entries)
      count = length(paged_entries)

      Phoenix.Controller.json(conn, %{
        data: data,
        pagination: %{
          total: total,
          limit: pagination.limit,
          offset: pagination.offset,
          count: count,
          has_more: pagination.offset + count < total
        }
      })
    else
      {:error, :invalid_pagination} ->
        conn
        |> Plug.Conn.put_status(:bad_request)
        |> Phoenix.Controller.json(%{error: "invalid_pagination"})
    end
  end

  def parse(params) when is_map(params) do
    with {:ok, limit} <- parse_limit(Map.get(params, "limit")),
         {:ok, offset} <- parse_offset(Map.get(params, "offset")) do
      {:ok, %{limit: limit, offset: offset}}
    end
  end

  defp parse_limit(nil), do: {:ok, @default_limit}
  defp parse_limit(value), do: parse_integer(value, min: 1, max: @max_limit)

  defp parse_offset(nil), do: {:ok, 0}
  defp parse_offset(value), do: parse_integer(value, min: 0)

  defp parse_integer(value, opts) when is_integer(value), do: validate_integer(value, opts)

  defp parse_integer(value, opts) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} -> validate_integer(integer, opts)
      _ -> {:error, :invalid_pagination}
    end
  end

  defp parse_integer(_value, _opts), do: {:error, :invalid_pagination}

  defp validate_integer(integer, opts) do
    min = Keyword.fetch!(opts, :min)
    max = Keyword.get(opts, :max)

    cond do
      integer < min -> {:error, :invalid_pagination}
      not is_nil(max) and integer > max -> {:error, :invalid_pagination}
      true -> {:ok, integer}
    end
  end
end
