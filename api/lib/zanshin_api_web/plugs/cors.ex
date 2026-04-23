defmodule ZanshinApiWeb.Plugs.Cors do
  @moduledoc """
  Minimal CORS handling for browser-based frontend API calls.
  """

  import Plug.Conn

  @default_allowed_origins [
    "http://localhost:3000",
    "http://127.0.0.1:3000"
  ]

  @allowed_methods "GET,POST,PUT,PATCH,DELETE,OPTIONS"
  @allowed_headers "authorization,content-type,x-requested-with"

  def init(opts), do: opts

  def call(conn, _opts) do
    origin = get_req_header(conn, "origin") |> List.first()
    allowed_origins = allowed_origins()

    if origin && origin in allowed_origins do
      conn =
        conn
        |> put_resp_header("access-control-allow-origin", origin)
        |> put_resp_header("vary", "Origin")
        |> put_resp_header("access-control-allow-methods", @allowed_methods)
        |> put_resp_header("access-control-allow-headers", @allowed_headers)
        |> put_resp_header("access-control-max-age", "86400")

      if conn.method == "OPTIONS" do
        conn
        |> send_resp(:no_content, "")
        |> halt()
      else
        conn
      end
    else
      conn
    end
  end

  defp allowed_origins do
    case System.get_env("CORS_ALLOWED_ORIGINS") do
      nil ->
        @default_allowed_origins

      origins ->
        origins
        |> String.split(",", trim: true)
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
        |> case do
          [] -> @default_allowed_origins
          parsed -> parsed
        end
    end
  end
end
