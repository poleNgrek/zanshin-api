defmodule ZanshinApi.TestSupport.Cabbage.Helpers do
  @moduledoc false

  import Plug.Conn

  alias ZanshinApi.AuthHelpers
  alias ZanshinApi.Events
  alias ZanshinApi.TestSupport.Cabbage.World
  alias ZanshinApiWeb.Endpoint

  @json_content_type "application/json"

  def new_world(conn) do
    %World{conn: put_req_header(conn, "accept", @json_content_type)}
  end

  def with_auth(%World{conn: conn} = world, role, subject \\ "bdd-user-1") do
    authorized_conn =
      conn
      |> put_req_header("authorization", AuthHelpers.bearer_token_for(role, subject))
      |> put_req_header("content-type", @json_content_type)

    %{world | conn: authorized_conn}
  end

  def with_idempotency_key(%World{conn: conn} = world, key) when is_binary(key) do
    %{world | conn: put_req_header(conn, "idempotency-key", key)}
  end

  def post_json(%World{conn: conn} = world, path, payload) do
    conn = Phoenix.ConnTest.dispatch(conn, Endpoint, :post, path, payload)
    %{world | conn: Phoenix.ConnTest.recycle(conn), last_response: conn}
  end

  def get_json(%World{conn: conn} = world, path) do
    conn = Phoenix.ConnTest.dispatch(conn, Endpoint, :get, path, %{})
    %{world | conn: Phoenix.ConnTest.recycle(conn), last_response: conn}
  end

  def remember(%World{assigns: assigns} = world, key, value) do
    %{world | assigns: Map.put(assigns, key, value)}
  end

  def fetch!(%World{assigns: assigns}, key) do
    Map.fetch!(assigns, key)
  end

  def score_match(world, match_id, key, side, target \\ "men") do
    world
    |> with_idempotency_key(key)
    |> post_json("/api/v1/matches/#{match_id}/score", %{
      "score_type" => "ippon",
      "side" => side,
      "target" => target
    })
  end

  def json_path_get(payload, path) do
    path
    |> String.split(".")
    |> Enum.reduce(payload, fn segment, acc ->
      case acc do
        %{} -> Map.get(acc, segment)
        _ -> nil
      end
    end)
  end

  def create_domain_event(attrs) do
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
end
