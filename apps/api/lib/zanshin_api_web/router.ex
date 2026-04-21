defmodule ZanshinApiWeb.Router do
  use ZanshinApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/v1", ZanshinApiWeb do
    pipe_through :api

    get "/health", HealthController, :index
    get "/matches", MatchController, :index
    post "/matches", MatchController, :create
    get "/matches/:id", MatchController, :show
    post "/matches/:id/transition", MatchStateController, :transition
  end
end
