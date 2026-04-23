defmodule ZanshinApiWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :zanshin_api

  @session_options [store: :cookie, key: "_zanshin_api_key", signing_salt: "zanshin-cookie-salt"]

  plug Plug.Static,
    at: "/",
    from: :zanshin_api,
    gzip: false,
    only: ZanshinApiWeb.static_paths()

  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
  plug ZanshinApiWeb.Plugs.Cors
  plug Plug.Parsers, parsers: [:urlencoded, :multipart, :json], pass: ["*/*"], json_decoder: Jason
  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug ZanshinApiWeb.Router
end
