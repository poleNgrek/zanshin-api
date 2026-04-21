import Config

config :zanshin_api,
  ecto_repos: [ZanshinApi.Repo]

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
