defmodule ZanshinApiWeb.Router do
  use ZanshinApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug ZanshinApiWeb.Plugs.RequireAuth
  end

  scope "/api/v1", ZanshinApiWeb do
    pipe_through :api

    get "/health", HealthController, :index
    get "/matches", MatchController, :index
    get "/matches/:id", MatchController, :show
  end

  scope "/api/v1", ZanshinApiWeb do
    pipe_through [:api, :api_auth]

    post "/matches", MatchController, :create
    post "/matches/:id/transition", MatchStateController, :transition
  end
end
