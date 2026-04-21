defmodule ZanshinApi.Domain.ModelPresenceTest do
  use ExUnit.Case, async: true

  test "all required domain model modules exist" do
    required_models = [
      ZanshinApi.Competitions.Tournament,
      ZanshinApi.Competitions.Division,
      ZanshinApi.Competitions.Competitor,
      ZanshinApi.Matches.Match,
      ZanshinApi.Matches.MatchEvent,
      ZanshinApi.Officials.Shinpan,
      ZanshinApi.Competitions.Shiaijo,
      ZanshinApi.Matches.Timer,
      ZanshinApi.Grading.GradingSession,
      ZanshinApi.Grading.GradingResult
    ]

    assert Enum.all?(required_models, &Code.ensure_loaded?/1)
  end
end
