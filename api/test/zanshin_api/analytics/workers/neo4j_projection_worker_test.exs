defmodule ZanshinApi.Analytics.Workers.Neo4jProjectionWorkerTest do
  use ZanshinApi.DataCase, async: true

  alias ZanshinApi.Analytics
  alias ZanshinApi.Analytics.Neo4jClient
  alias ZanshinApi.Analytics.Projector
  alias ZanshinApi.Analytics.Projectors.Neo4jMatchProjector
  alias ZanshinApi.Analytics.Workers.Neo4jProjectionWorker
  alias ZanshinApi.Events
  alias ZanshinApi.Events.DomainEvent

  defmodule Neo4jClientSpy do
    @behaviour Neo4jClient

    @impl true
    def execute(cypher, params, opts) do
      notify_pid = Keyword.fetch!(opts, :notify_pid)
      send(notify_pid, {:neo4j_projection_call, cypher, params})
      :ok
    end

    @impl true
    def query(_cypher, _params, _opts), do: {:ok, []}
  end

  defmodule OrderedProjector do
    @behaviour Projector

    @impl true
    def project(event, opts) do
      notify_pid = Keyword.fetch!(opts, :notify_pid)
      send(notify_pid, {:ordered_projection_call, event.id, event.event_type})
      :ok
    end
  end

  defmodule FlakyProjector do
    @behaviour Projector

    @impl true
    def project(event, opts) do
      failure_counter = Keyword.fetch!(opts, :failure_counter)

      remaining_failures =
        Agent.get_and_update(failure_counter, fn count ->
          {count, max(count - 1, 0)}
        end)

      if remaining_failures > 0 do
        {:error, :simulated_projection_failure}
      else
        notify_pid = Keyword.fetch!(opts, :notify_pid)
        send(notify_pid, {:flaky_projection_success, event.id})
        :ok
      end
    end
  end

  describe "run_once/1" do
    test "projects unprocessed match transition event and advances checkpoint" do
      event_occurred_at = DateTime.utc_now() |> DateTime.truncate(:second)
      match_id = Ecto.UUID.generate()

      assert {:ok, domain_event} =
               Events.create_domain_event(%{
                 event_type: "match.transitioned",
                 event_version: 1,
                 aggregate_type: "match",
                 aggregate_id: match_id,
                 occurred_at: event_occurred_at,
                 actor_role: "admin",
                 source: "test",
                 payload: %{
                   "event" => "prepare",
                   "from_state" => "scheduled",
                   "to_state" => "ready",
                   "match_id" => match_id
                 }
               })

      assert {:ok, 1} =
               Neo4jProjectionWorker.run_once(
                 projection_name: "neo4j_projection_worker_test",
                 projector: Neo4jMatchProjector,
                 projector_options: [neo4j_client: Neo4jClientSpy, notify_pid: self()]
               )

      assert_receive {:neo4j_projection_call, cypher, params}
      assert cypher =~ "MERGE (m:Match"
      assert params.match_id == match_id
      assert params.to_state == "ready"

      reloaded_event = Repo.get!(DomainEvent, domain_event.id)
      assert not is_nil(reloaded_event.processed_at)

      checkpoint = Analytics.get_projection_checkpoint("neo4j_projection_worker_test")
      assert checkpoint.last_event_id == domain_event.id
      assert checkpoint.last_event_inserted_at == domain_event.inserted_at
    end

    test "projection failure leaves event unprocessed and without checkpoint" do
      match_id = Ecto.UUID.generate()
      projection_name = "neo4j_projection_failure_test"

      assert {:ok, domain_event} =
               create_domain_event(%{
                 event_type: "match.transitioned",
                 aggregate_id: match_id,
                 payload: %{
                   "event" => "prepare",
                   "from_state" => "scheduled",
                   "to_state" => "ready",
                   "match_id" => match_id
                 }
               })

      event_id = domain_event.id

      assert {:error, {:projection_failed, ^event_id, :simulated_projection_failure}} =
               Neo4jProjectionWorker.run_once(
                 projection_name: projection_name,
                 projector: FlakyProjector,
                 projector_options: [
                   failure_counter: start_failure_counter(1),
                   notify_pid: self()
                 ]
               )

      reloaded_event = Repo.get!(DomainEvent, domain_event.id)
      assert is_nil(reloaded_event.processed_at)
      assert is_nil(Analytics.get_projection_checkpoint(projection_name))
    end

    test "retry succeeds after transient projection failure" do
      match_id = Ecto.UUID.generate()
      projection_name = "neo4j_projection_retry_test"
      failure_counter = start_failure_counter(1)

      assert {:ok, domain_event} =
               create_domain_event(%{
                 event_type: "match.transitioned",
                 aggregate_id: match_id,
                 payload: %{
                   "event" => "prepare",
                   "from_state" => "scheduled",
                   "to_state" => "ready",
                   "match_id" => match_id
                 }
               })

      event_id = domain_event.id

      assert {:error, {:projection_failed, ^event_id, :simulated_projection_failure}} =
               Neo4jProjectionWorker.run_once(
                 projection_name: projection_name,
                 projector: FlakyProjector,
                 projector_options: [failure_counter: failure_counter, notify_pid: self()]
               )

      assert {:ok, 1} =
               Neo4jProjectionWorker.run_once(
                 projection_name: projection_name,
                 projector: FlakyProjector,
                 projector_options: [failure_counter: failure_counter, notify_pid: self()]
               )

      assert_receive {:flaky_projection_success, ^event_id}

      reloaded_event = Repo.get!(DomainEvent, domain_event.id)
      assert not is_nil(reloaded_event.processed_at)

      checkpoint = Analytics.get_projection_checkpoint(projection_name)
      assert checkpoint.last_event_id == domain_event.id
    end

    test "projects events in insertion order and checkpoints last projected event" do
      projection_name = "neo4j_projection_ordering_test"
      match_id = Ecto.UUID.generate()

      assert {:ok, first_event} =
               create_domain_event(%{
                 event_type: "match.transitioned",
                 aggregate_id: match_id,
                 payload: %{
                   "event" => "prepare",
                   "from_state" => "scheduled",
                   "to_state" => "ready",
                   "match_id" => match_id
                 }
               })

      Process.sleep(1_100)

      assert {:ok, second_event} =
               create_domain_event(%{
                 event_type: "match.score_recorded",
                 aggregate_id: match_id,
                 payload: %{
                   "match_id" => match_id,
                   "score_event_id" => Ecto.UUID.generate(),
                   "score_type" => "ippon",
                   "side" => "aka",
                   "target" => "men"
                 }
               })

      first_event_id = first_event.id
      second_event_id = second_event.id

      assert {:ok, 2} =
               Neo4jProjectionWorker.run_once(
                 projection_name: projection_name,
                 projector: OrderedProjector,
                 projector_options: [notify_pid: self()]
               )

      assert_receive {:ordered_projection_call, ^first_event_id, "match.transitioned"}
      assert_receive {:ordered_projection_call, ^second_event_id, "match.score_recorded"}

      checkpoint = Analytics.get_projection_checkpoint(projection_name)
      assert checkpoint.last_event_id == second_event.id
    end

    test "second replay pass is idempotent when no events remain" do
      projection_name = "neo4j_projection_replay_idempotent_test"
      match_id = Ecto.UUID.generate()

      assert {:ok, event} =
               create_domain_event(%{
                 event_type: "match.transitioned",
                 aggregate_id: match_id,
                 payload: %{
                   "event" => "prepare",
                   "from_state" => "scheduled",
                   "to_state" => "ready",
                   "match_id" => match_id
                 }
               })

      event_id = event.id

      assert {:ok, 1} =
               Neo4jProjectionWorker.run_once(
                 projection_name: projection_name,
                 projector: OrderedProjector,
                 projector_options: [notify_pid: self()]
               )

      assert_receive {:ordered_projection_call, ^event_id, "match.transitioned"}

      assert {:ok, 0} =
               Neo4jProjectionWorker.run_once(
                 projection_name: projection_name,
                 projector: OrderedProjector,
                 projector_options: [notify_pid: self()]
               )

      refute_receive {:ordered_projection_call, _, _}
    end

    test "replayed stale event does not regress checkpoint after newer projection" do
      projection_name = "neo4j_projection_drift_guard_test"
      match_id = Ecto.UUID.generate()

      assert {:ok, first_event} =
               create_domain_event(%{
                 event_type: "match.transitioned",
                 aggregate_id: match_id,
                 payload: %{
                   "event" => "prepare",
                   "from_state" => "scheduled",
                   "to_state" => "ready",
                   "match_id" => match_id
                 }
               })

      Process.sleep(1_100)

      assert {:ok, second_event} =
               create_domain_event(%{
                 event_type: "match.score_recorded",
                 aggregate_id: match_id,
                 payload: %{
                   "match_id" => match_id,
                   "score_event_id" => Ecto.UUID.generate(),
                   "score_type" => "ippon",
                   "side" => "aka",
                   "target" => "men"
                 }
               })

      first_event_id = first_event.id
      second_event_id = second_event.id

      assert {:ok, 2} =
               Neo4jProjectionWorker.run_once(
                 projection_name: projection_name,
                 projector: OrderedProjector,
                 projector_options: [notify_pid: self()]
               )

      assert_receive {:ordered_projection_call, ^first_event_id, "match.transitioned"}
      assert_receive {:ordered_projection_call, ^second_event_id, "match.score_recorded"}

      checkpoint_after_full_pass = Analytics.get_projection_checkpoint(projection_name)
      assert checkpoint_after_full_pass.last_event_id == second_event.id

      # Simulate a stale replay candidate by unmarking the older event as processed.
      first_event
      |> then(&Repo.get!(DomainEvent, &1.id))
      |> Ecto.Changeset.change(processed_at: nil)
      |> Repo.update!()

      assert {:ok, 1} =
               Neo4jProjectionWorker.run_once(
                 projection_name: projection_name,
                 projector: OrderedProjector,
                 projector_options: [notify_pid: self()]
               )

      assert_receive {:ordered_projection_call, ^first_event_id, "match.transitioned"}

      checkpoint_after_stale_replay = Analytics.get_projection_checkpoint(projection_name)
      assert checkpoint_after_stale_replay.last_event_id == second_event.id
      assert checkpoint_after_stale_replay.last_event_inserted_at == second_event.inserted_at
    end
  end

  defp create_domain_event(attrs) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    default_attrs = %{
      event_type: "match.transitioned",
      event_version: 1,
      aggregate_type: "match",
      aggregate_id: Ecto.UUID.generate(),
      occurred_at: now,
      actor_role: "admin",
      source: "test",
      payload: %{}
    }

    Events.create_domain_event(Map.merge(default_attrs, attrs))
  end

  defp start_failure_counter(initial_count) do
    {:ok, pid} = Agent.start_link(fn -> initial_count end)
    pid
  end
end
