defmodule ZanshinApi.Analytics.Neo4jClient do
  @moduledoc """
  Behaviour for Neo4j command execution adapters.
  """

  @callback execute(cypher :: String.t(), params :: map(), keyword()) :: :ok | {:error, term()}
  @callback query(cypher :: String.t(), params :: map(), keyword()) ::
              {:ok, [map()]} | {:error, term()}
end
