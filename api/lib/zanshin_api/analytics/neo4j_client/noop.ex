defmodule ZanshinApi.Analytics.Neo4jClient.Noop do
  @moduledoc """
  Placeholder Neo4j adapter used until the Bolt/HTTP client integration is wired.
  """

  @behaviour ZanshinApi.Analytics.Neo4jClient

  require Logger

  @impl true
  def execute(cypher, params, _opts) do
    Logger.debug(fn ->
      "Neo4j noop projection call. cypher=#{cypher} params=#{inspect(params)}"
    end)

    :ok
  end

  @impl true
  def query(cypher, params, _opts) do
    Logger.debug(fn ->
      "Neo4j noop query call. cypher=#{cypher} params=#{inspect(params)}"
    end)

    {:ok, []}
  end
end
