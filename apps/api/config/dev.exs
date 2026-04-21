import Config

config :zanshin_api, ZanshinApi.Repo,
  username: "zanshin",
  password: "zanshin",
  hostname: System.get_env("DB_HOST", "localhost"),
  database: "zanshin_dev",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :zanshin_api, ZanshinApiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT") || "4000")],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev-secret-key-base-dev-secret-key-base",
  watchers: []

config :zanshin_api, dev_routes: true

config :logger, :default_formatter, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
