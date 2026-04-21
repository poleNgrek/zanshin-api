defmodule ZanshinApiWeb.Router do
  use ZanshinApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/v1", ZanshinApiWeb do
    pipe_through :api

    get "/health", HealthController, :index
    post "/matches/transition", MatchStateController, :transition
  end
end
