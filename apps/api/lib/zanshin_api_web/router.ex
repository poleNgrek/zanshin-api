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
    get "/team_matches", TeamMatchController, :index
    get "/gradings/examiners", GradingExaminerController, :index
    get "/gradings/sessions", GradingSessionController, :index
    get "/gradings/sessions/:id/results", GradingResultController, :index
    get "/gradings/sessions/:id/panel_assignments", GradingExaminerController, :panel
    get "/gradings/results/:id/votes", GradingResultController, :votes
    get "/gradings/results/:id/notes", GradingResultController, :notes
    get "/matches", MatchController, :index
    get "/matches/:id", MatchController, :show
    get "/matches/:id/score", MatchScoreController, :index
  end

  scope "/api/v1", ZanshinApiWeb do
    pipe_through [:api, :api_auth]

    post "/tournaments", TournamentController, :create
    get "/tournaments/:id/export", TournamentController, :export
    post "/divisions", DivisionController, :create
    put "/divisions/:id/rules", DivisionRuleController, :upsert
    post "/division_stages", DivisionStageController, :create
    post "/division_medal_results", DivisionMedalResultController, :create
    post "/divisions/:id/compute_results", DivisionMedalResultController, :compute
    post "/division_special_awards", DivisionSpecialAwardController, :create
    post "/competitors", CompetitorController, :create
    post "/teams", TeamController, :create
    post "/teams/:id/members", TeamController, :add_member
    post "/team_matches", TeamMatchController, :create
    post "/gradings/examiners", GradingExaminerController, :create
    post "/gradings/sessions", GradingSessionController, :create
    post "/gradings/sessions/:id/results", GradingResultController, :create
    post "/gradings/sessions/:id/panel_assignments", GradingExaminerController, :assign
    post "/gradings/results/:id/votes", GradingResultController, :create_vote
    post "/gradings/results/:id/notes", GradingResultController, :create_note
    post "/matches", MatchController, :create
    post "/matches/:id/transition", MatchStateController, :transition
    post "/matches/:id/score", MatchScoreController, :create
  end
end
