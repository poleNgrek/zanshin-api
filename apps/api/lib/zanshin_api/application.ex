defmodule ZanshinApi.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ZanshinApi.Repo,
      {Phoenix.PubSub, name: ZanshinApi.PubSub},
      ZanshinApiWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: ZanshinApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    ZanshinApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
