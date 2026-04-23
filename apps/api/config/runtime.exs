import Config

neo4j_bolt_url = System.get_env("NEO4J_BOLT_URL")
neo4j_username = System.get_env("NEO4J_USERNAME")
neo4j_password = System.get_env("NEO4J_PASSWORD")
neo4j_pool_size = System.get_env("NEO4J_POOL_SIZE")
neo4j_connection_timeout_ms = System.get_env("NEO4J_CONNECTION_TIMEOUT_MS")
neo4j_query_timeout_ms = System.get_env("NEO4J_QUERY_TIMEOUT_MS")
analytics_summary_source = System.get_env("ANALYTICS_SUMMARY_SOURCE")

analytics_summary_source_value =
  case analytics_summary_source do
    "neo4j" -> :neo4j
    "postgres" -> :postgres
    _ -> :neo4j
  end

config :zanshin_api, ZanshinApi.Analytics.Neo4jClient.Bolt,
  url: neo4j_bolt_url || "bolt://localhost:7687",
  username: neo4j_username || "neo4j",
  password: neo4j_password || "zanshin_neo4j",
  pool_size: String.to_integer(neo4j_pool_size || "5"),
  connection_timeout_ms: String.to_integer(neo4j_connection_timeout_ms || "15000"),
  query_timeout_ms: String.to_integer(neo4j_query_timeout_ms || "10000")

config :neo4j_ex,
  drivers: [
    analytics_projection: [
      uri: neo4j_bolt_url || "bolt://localhost:7687",
      auth: {neo4j_username || "neo4j", neo4j_password || "zanshin_neo4j"},
      connection_timeout: String.to_integer(neo4j_connection_timeout_ms || "15000"),
      query_timeout: String.to_integer(neo4j_query_timeout_ms || "10000"),
      max_pool_size: String.to_integer(neo4j_pool_size || "5")
    ]
  ]

config :zanshin_api, :analytics_summary_source, analytics_summary_source_value

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      Example: ecto://USER:PASS@HOST/DATABASE
      """

  config :zanshin_api, ZanshinApi.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "environment variable SECRET_KEY_BASE is missing."

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :zanshin_api, ZanshinApiWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base,
    server: true
end
