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

config :zanshin_api, :neo4j_client, ZanshinApi.Analytics.Neo4jClient.Bolt
config :zanshin_api, :analytics_summary_source, :neo4j

config :zanshin_api, ZanshinApi.Analytics.Neo4jClient.Bolt,
  url: "bolt://localhost:7687",
  username: "neo4j",
  password: "zanshin_neo4j",
  driver_name: :analytics_projection,
  pool_size: 5,
  connection_timeout_ms: 15_000,
  query_timeout_ms: 10_000

config :neo4j_ex,
  drivers: [
    analytics_projection: [
      uri: "bolt://localhost:7687",
      auth: {"neo4j", "zanshin_neo4j"},
      connection_timeout: 15_000,
      query_timeout: 10_000,
      max_pool_size: 5
    ]
  ]

config :zanshin_api, ZanshinApi.Analytics.Workers.Neo4jProjectionWorker,
  enabled: false,
  poll_interval_ms: 2_000,
  batch_size: 100,
  projection_name: "neo4j_match_projection_v1"

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
