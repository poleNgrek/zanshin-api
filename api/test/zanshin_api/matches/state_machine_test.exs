defmodule ZanshinApi.Matches.StateMachineTest do
  use ExUnit.Case, async: true

  alias ZanshinApi.Matches.StateMachine

  describe "transition/2" do
    test "allows valid lifecycle transitions" do
      assert {:ok, :ready} = StateMachine.transition(:scheduled, :prepare)
      assert {:ok, :ongoing} = StateMachine.transition(:ready, :start)
      assert {:ok, :paused} = StateMachine.transition(:ongoing, :pause)
      assert {:ok, :ongoing} = StateMachine.transition(:paused, :resume)
      assert {:ok, :completed} = StateMachine.transition(:ongoing, :complete)
      assert {:ok, :verified} = StateMachine.transition(:completed, :verify)
    end

    test "rejects invalid transition" do
      assert {:error, {:invalid_transition, :scheduled, :verify}} =
               StateMachine.transition(:scheduled, :verify)
    end
  end

  describe "parsers" do
    test "parse_event/1 accepts known events and rejects unknown event" do
      assert {:ok, :prepare} = StateMachine.parse_event("prepare")
      assert {:error, :invalid_event} = StateMachine.parse_event("unknown")
    end

    test "parse_state/1 accepts known states and rejects unknown state" do
      assert {:ok, :scheduled} = StateMachine.parse_state("scheduled")
      assert {:error, :invalid_state} = StateMachine.parse_state("unknown")
    end
  end
end
