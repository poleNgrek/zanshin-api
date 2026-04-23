defmodule ZanshinApiWeb.RealtimeEventsController do
  use ZanshinApiWeb, :controller

  import Ecto.Query, warn: false

  alias ZanshinApi.Events.DomainEvent
  alias ZanshinApi.Repo

  @default_limit 25
  @max_limit 100

  def match_stream(conn, params) do
    with :ok <- authorize_read(conn),
         {:ok, tournament_id} <- require_tournament_id(params) do
      limit = parse_limit(Map.get(params, "limit"))
      since_id = Map.get(params, "since_id")
      events = list_match_events(tournament_id, since_id, limit)

      payload = %{
        tournament_id: tournament_id,
        count: length(events),
        events: Enum.map(events, &serialize_event/1)
      }

      conn
      |> put_resp_content_type("text/event-stream")
      |> put_resp_header("cache-control", "no-cache")
      |> put_resp_header("connection", "keep-alive")
      |> send_chunked(200)
      |> chunk_sse("match_events_snapshot", payload)
    else
      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "forbidden"})

      {:error, :tournament_id_required} ->
        conn |> put_status(:bad_request) |> json(%{error: "tournament_id_required"})
    end
  end

  defp authorize_read(conn) do
    case conn.assigns[:current_role] do
      :admin -> :ok
      _ -> {:error, :forbidden}
    end
  end

  defp require_tournament_id(params) do
    case Map.get(params, "tournament_id") do
      nil -> {:error, :tournament_id_required}
      tournament_id -> {:ok, tournament_id}
    end
  end

  defp parse_limit(nil), do: @default_limit

  defp parse_limit(raw_limit) when is_binary(raw_limit) do
    case Integer.parse(raw_limit) do
      {value, ""} when value > 0 -> min(value, @max_limit)
      _ -> @default_limit
    end
  end

  defp parse_limit(_), do: @default_limit

  defp list_match_events(tournament_id, since_id, limit) do
    base_query =
      DomainEvent
      |> where([event], event.aggregate_type == "match")
      |> where([event], fragment("?->>'tournament_id' = ?", event.payload, ^tournament_id))

    query =
      case since_event_inserted_at(since_id) do
        nil -> base_query
        inserted_at -> where(base_query, [event], event.inserted_at > ^inserted_at)
      end

    query
    |> order_by([event], asc: event.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  defp since_event_inserted_at(nil), do: nil

  defp since_event_inserted_at(since_id) do
    case Repo.get(DomainEvent, since_id) do
      nil -> nil
      event -> event.inserted_at
    end
  end

  defp serialize_event(event) do
    %{
      id: event.id,
      event_type: event.event_type,
      aggregate_id: event.aggregate_id,
      occurred_at: event.occurred_at,
      actor_role: event.actor_role,
      payload: event.payload
    }
  end

  defp chunk_sse(conn, event_name, payload) do
    event_json = Jason.encode!(payload)

    case chunk(conn, "event: #{event_name}\ndata: #{event_json}\n\n") do
      {:ok, conn} -> Plug.Conn.halt(conn)
      {:error, :closed} -> Plug.Conn.halt(conn)
    end
  end
end
