defmodule ZanshinApi.Analytics.Workers.Neo4jProjectionWorker do
  @moduledoc """
  Polling worker skeleton that consumes unprocessed domain events and projects them to Neo4j.
  """

  use GenServer

  alias ZanshinApi.Analytics
  alias ZanshinApi.Analytics.Projectors.Neo4jMatchProjector
  alias ZanshinApi.Events

  @default_projection_name "neo4j_match_projection_v1"
  @default_poll_interval_ms 2_000
  @default_batch_size 100

  def start_link(init_opts) do
    GenServer.start_link(__MODULE__, init_opts, name: __MODULE__)
  end

  @impl true
  def init(init_opts) do
    state = %{
      poll_interval_ms: Keyword.get(init_opts, :poll_interval_ms, @default_poll_interval_ms),
      batch_size: Keyword.get(init_opts, :batch_size, @default_batch_size),
      projection_name: Keyword.get(init_opts, :projection_name, @default_projection_name),
      projector: Keyword.get(init_opts, :projector, Neo4jMatchProjector),
      projector_options: Keyword.get(init_opts, :projector_options, []),
      events_module: Keyword.get(init_opts, :events_module, Events),
      analytics_module: Keyword.get(init_opts, :analytics_module, Analytics)
    }

    schedule_next_run(state.poll_interval_ms)
    {:ok, state}
  end

  @impl true
  def handle_info(:project_once, state) do
    _ = execute_once(state)
    schedule_next_run(state.poll_interval_ms)
    {:noreply, state}
  end

  def run_once(opts \\ []) do
    execute_once(%{
      batch_size: Keyword.get(opts, :batch_size, @default_batch_size),
      projection_name: Keyword.get(opts, :projection_name, @default_projection_name),
      projector: Keyword.get(opts, :projector, Neo4jMatchProjector),
      projector_options: Keyword.get(opts, :projector_options, []),
      events_module: Keyword.get(opts, :events_module, Events),
      analytics_module: Keyword.get(opts, :analytics_module, Analytics)
    })
  end

  defp execute_once(state) do
    state.events_module.list_unprocessed_events(state.batch_size)
    |> Enum.reduce_while({:ok, 0}, fn event, {:ok, count} ->
      case state.projector.project(event, state.projector_options) do
        :ok ->
          with {:ok, _updated_event} <- state.events_module.mark_processed(event.id),
               {:ok, _checkpoint} <-
                 state.analytics_module.upsert_checkpoint(state.projection_name, event) do
            {:cont, {:ok, count + 1}}
          else
            {:error, reason} ->
              {:halt, {:error, {:checkpoint_or_mark_failed, event.id, reason}}}
          end

        {:error, reason} ->
          {:halt, {:error, {:projection_failed, event.id, reason}}}
      end
    end)
  end

  defp schedule_next_run(interval_ms) do
    Process.send_after(self(), :project_once, interval_ms)
  end
end
