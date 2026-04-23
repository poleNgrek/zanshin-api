defmodule ZanshinApi.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        ZanshinApi.Repo,
        {Phoenix.PubSub, name: ZanshinApi.PubSub},
        ZanshinApiWeb.Endpoint
      ] ++ analytics_children()

    opts = [strategy: :one_for_one, name: ZanshinApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    ZanshinApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp analytics_children do
    worker_config =
      Application.get_env(:zanshin_api, ZanshinApi.Analytics.Workers.Neo4jProjectionWorker, [])

    if Keyword.get(worker_config, :enabled, false) do
      [{ZanshinApi.Analytics.Workers.Neo4jProjectionWorker, worker_config}]
    else
      []
    end
  end
end
