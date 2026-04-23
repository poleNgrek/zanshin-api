import Config

config :zanshin_api, ZanshinApi.Repo,
  username: "zanshin",
  password: "zanshin",
  hostname: System.get_env("DB_HOST", "localhost"),
  database: "zanshin_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5

config :zanshin_api, ZanshinApiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test-secret-key-base-test-secret-key-base",
  server: false

config :logger, level: :warning

config :zanshin_api, ZanshinApi.Auth, mode: :oauth_jwks

config :phoenix, :plug_init_mode, :runtime

config :cabbage,
  features: "test/features/"
