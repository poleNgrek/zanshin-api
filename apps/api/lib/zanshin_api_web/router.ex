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
    get "/tournaments", TournamentController, :index
    get "/divisions", DivisionController, :index
    get "/divisions/:id/rules", DivisionRuleController, :show
    get "/division_stages", DivisionStageController, :index
    get "/division_medal_results", DivisionMedalResultController, :index
    get "/division_special_awards", DivisionSpecialAwardController, :index
    get "/competitors", CompetitorController, :index
    get "/teams", TeamController, :index
    get "/teams/:id/members", TeamController, :members
    get "/matches", MatchController, :index
    get "/matches/:id", MatchController, :show
    get "/matches/:id/score", MatchScoreController, :index
  end

  scope "/api/v1", ZanshinApiWeb do
    pipe_through [:api, :api_auth]

    post "/tournaments", TournamentController, :create
    post "/divisions", DivisionController, :create
    put "/divisions/:id/rules", DivisionRuleController, :upsert
    post "/division_stages", DivisionStageController, :create
    post "/division_medal_results", DivisionMedalResultController, :create
    post "/division_special_awards", DivisionSpecialAwardController, :create
    post "/competitors", CompetitorController, :create
    post "/teams", TeamController, :create
    post "/teams/:id/members", TeamController, :add_member
    post "/matches", MatchController, :create
    post "/matches/:id/transition", MatchStateController, :transition
    post "/matches/:id/score", MatchScoreController, :create
  end
end
