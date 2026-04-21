import Config

config :zanshin_api,
  ecto_repos: [ZanshinApi.Repo]

config :zanshin_api, ZanshinApi.Auth.JWT,
  secret: System.get_env("JWT_SECRET") || "zanshin-dev-jwt-secret-change-me",
  issuer: "zanshin_api"

config :zanshin_api, ZanshinApi.Auth, mode: :oauth_jwks

config :zanshin_api, ZanshinApi.Auth.OAuth,
  issuer: System.get_env("OAUTH_ISSUER") || "https://auth.example.com",
  audience: System.get_env("OAUTH_AUDIENCE") || "zanshin-api",
  jwks_url: System.get_env("OAUTH_JWKS_URL"),
  jwks: nil,
  jwks_cache_ttl_seconds: 300

config :zanshin_api, ZanshinApiWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: ZanshinApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ZanshinApi.PubSub,
  live_view: [signing_salt: "zanshin-signing-salt"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
