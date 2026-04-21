defmodule ZanshinApi.Domain.ModelPresenceTest do
  use ExUnit.Case, async: true

  test "all required domain model modules exist" do
    required_models = [
      ZanshinApi.Competitions.Tournament,
      ZanshinApi.Competitions.Division,
      ZanshinApi.Competitions.Competitor,
      ZanshinApi.Competitions.DivisionRule,
      ZanshinApi.Competitions.DivisionStage,
      ZanshinApi.Competitions.DivisionMedalResult,
      ZanshinApi.Competitions.DivisionSpecialAward,
      ZanshinApi.Teams.Team,
      ZanshinApi.Teams.TeamMatch,
      ZanshinApi.Teams.TeamMember,
      ZanshinApi.Matches.Match,
      ZanshinApi.Matches.MatchEvent,
      ZanshinApi.Matches.ScoreEvent,
      ZanshinApi.Officials.Shinpan,
      ZanshinApi.Competitions.Shiaijo,
      ZanshinApi.Matches.Timer,
      ZanshinApi.Grading.GradingSession,
      ZanshinApi.Grading.GradingResult,
      ZanshinApi.Grading.GradingExaminer,
      ZanshinApi.Grading.GradingPanelAssignment,
      ZanshinApi.Grading.GradingVote,
      ZanshinApi.Grading.GradingNote
    ]

    assert Enum.all?(required_models, &Code.ensure_loaded?/1)
  end
end
