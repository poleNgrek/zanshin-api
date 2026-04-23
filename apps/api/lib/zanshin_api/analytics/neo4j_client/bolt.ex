defmodule ZanshinApi.Analytics.Neo4jClient.Bolt do
  @moduledoc """
  Neo4j adapter using the Bolt protocol via Neo4jEx.
  """

  @behaviour ZanshinApi.Analytics.Neo4jClient

  require Logger

  @impl true
  def execute(cypher, params, opts) when is_binary(cypher) and is_map(params) do
    query_timeout_ms =
      Keyword.get(opts, :query_timeout_ms, config_value(:query_timeout_ms, 10_000))

    with {:ok, _response} <- Neo4jEx.run(driver_name(), cypher, params, timeout: query_timeout_ms) do
      :ok
    else
      {:error, reason} ->
        Logger.error(
          "Neo4j Bolt query failed: #{inspect(reason)} statement=#{truncate_statement(cypher)}"
        )

        {:error, {:neo4j_query_failed, reason}}
    end
  rescue
    error ->
      Logger.error("Neo4j Bolt execution raised: #{Exception.message(error)}")
      {:error, {:neo4j_execution_exception, error}}
  end

  @impl true
  def query(cypher, params, opts) when is_binary(cypher) and is_map(params) do
    query_timeout_ms =
      Keyword.get(opts, :query_timeout_ms, config_value(:query_timeout_ms, 10_000))

    with {:ok, response} <- Neo4jEx.run(driver_name(), cypher, params, timeout: query_timeout_ms) do
      {:ok, normalize_records(response)}
    else
      {:error, reason} ->
        Logger.error(
          "Neo4j Bolt read query failed: #{inspect(reason)} statement=#{truncate_statement(cypher)}"
        )

        {:error, {:neo4j_query_failed, reason}}
    end
  rescue
    error ->
      Logger.error("Neo4j Bolt read execution raised: #{Exception.message(error)}")
      {:error, {:neo4j_execution_exception, error}}
  end

  def child_options do
    [
      name: driver_name(),
      uri: bolt_url(),
      auth: {config_value(:username, "neo4j"), config_value(:password, "zanshin_neo4j")},
      connection_timeout: config_value(:connection_timeout_ms, 15_000),
      query_timeout: config_value(:query_timeout_ms, 10_000),
      user_agent: "zanshin_api_projection_worker/1.0"
    ]
    |> maybe_put_pool_size()
  end

  defp config_value(key, default) do
    Application.get_env(:zanshin_api, __MODULE__, [])
    |> Keyword.get(key, default)
  end

  defp bolt_url do
    base_url = config_value(:url, "bolt://localhost:7687")
    uri = URI.parse(base_url)
    username = config_value(:username, nil)
    password = config_value(:password, nil)

    cond do
      not is_nil(uri.userinfo) ->
        base_url

      is_binary(username) and username != "" and is_binary(password) and password != "" ->
        %URI{uri | userinfo: "#{username}:#{password}"} |> URI.to_string()

      true ->
        base_url
    end
  end

  defp maybe_put_pool_size(options) do
    case config_value(:pool_size, nil) do
      nil ->
        options

      pool_size when is_integer(pool_size) and pool_size > 0 ->
        Keyword.put(options, :max_pool_size, pool_size)

      _ ->
        options
    end
  end

  defp driver_name do
    config_value(:driver_name, :analytics_projection)
  end

  defp normalize_records(%{records: records}) when is_list(records) do
    Enum.map(records, &Neo4j.Result.Record.to_map/1)
  end

  defp normalize_records(_), do: []

  defp truncate_statement(statement) when byte_size(statement) <= 180, do: statement
  defp truncate_statement(statement), do: binary_part(statement, 0, 180) <> "..."
end
