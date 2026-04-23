defmodule ZanshinApi.Analytics do
  @moduledoc """
  Analytics projection helpers.
  """

  import Ecto.Query, warn: false

  alias ZanshinApi.Analytics.ProjectionCheckpoint
  alias ZanshinApi.Events.DomainEvent
  alias ZanshinApi.Repo

  @default_limit 50
  @max_limit 200

  def get_projection_checkpoint(projection_name) when is_binary(projection_name) do
    Repo.get_by(ProjectionCheckpoint, projection_name: projection_name)
  end

  def upsert_checkpoint(projection_name, %DomainEvent{} = event)
      when is_binary(projection_name) do
    attrs = %{
      projection_name: projection_name,
      last_event_id: event.id,
      last_event_inserted_at: event.inserted_at
    }

    %ProjectionCheckpoint{}
    |> ProjectionCheckpoint.changeset(attrs)
    |> Repo.insert(
      on_conflict: [
        set: [
          last_event_id: event.id,
          last_event_inserted_at: event.inserted_at,
          updated_at: DateTime.utc_now()
        ]
      ],
      conflict_target: :projection_name
    )
  end

  def match_summary(params) when is_map(params) do
    with {:ok, filters} <- normalize_filters(params) do
      match_summary_from_source(filters)
    end
  end

  def dashboard_event_feed(params) when is_map(params) do
    with {:ok, filters} <- normalize_filters(params) do
      dashboard_event_feed_from_source(filters)
    end
  end

  def match_state_overview(params) when is_map(params) do
    with {:ok, filters} <- normalize_filters(params) do
      match_state_overview_from_source(filters)
    end
  end

  def dashboard_overview(params) when is_map(params) do
    with {:ok, filters} <- normalize_filters(params),
         {:ok, summary} <- match_summary_from_source(filters),
         {:ok, state_overview} <- match_state_overview_from_source(filters),
         {:ok, event_feed} <- dashboard_event_feed_from_source(filters),
         {:ok, throughput_trend} <- throughput_trend_from_source(filters),
         {:ok, top_active_matches} <- top_active_matches_from_source(filters),
         {:ok, actor_role_activity} <- actor_role_activity_from_source(filters) do
      {:ok,
       %{
         scope: summary.scope,
         data_source: summary.data_source,
         summary: %{
           kpis: summary.kpis,
           event_type_breakdown: summary.event_type_breakdown
         },
         state_overview: %{
           state_counts: state_overview.state_counts
         },
         recent_events: event_feed.events,
         insights: %{
           throughput_trend: throughput_trend,
           top_active_matches: top_active_matches,
           actor_role_activity: actor_role_activity
         }
       }}
    end
  end

  defp match_summary_from_source(filters) do
    case analytics_summary_source() do
      :neo4j ->
        case match_summary_from_neo4j(filters) do
          {:ok, summary} ->
            {:ok, summary}

          {:error, _reason} ->
            {:ok, match_summary_from_postgres(filters, "postgres_fallback")}
        end

      _ ->
        {:ok, match_summary_from_postgres(filters, "postgres")}
    end
  end

  defp dashboard_event_feed_from_source(filters) do
    case analytics_summary_source() do
      :neo4j ->
        case dashboard_event_feed_from_neo4j(filters) do
          {:ok, payload} -> {:ok, payload}
          {:error, _} -> {:ok, dashboard_event_feed_from_postgres(filters, "postgres_fallback")}
        end

      _ ->
        {:ok, dashboard_event_feed_from_postgres(filters, "postgres")}
    end
  end

  defp match_state_overview_from_source(filters) do
    case analytics_summary_source() do
      :neo4j ->
        case match_state_overview_from_neo4j(filters) do
          {:ok, payload} -> {:ok, payload}
          {:error, _} -> {:ok, match_state_overview_from_postgres(filters, "postgres_fallback")}
        end

      _ ->
        {:ok, match_state_overview_from_postgres(filters, "postgres")}
    end
  end

  defp throughput_trend_from_source(filters) do
    case analytics_summary_source() do
      :neo4j ->
        case throughput_trend_from_neo4j(filters) do
          {:ok, payload} -> {:ok, payload}
          {:error, _} -> {:ok, throughput_trend_from_postgres(filters)}
        end

      _ ->
        {:ok, throughput_trend_from_postgres(filters)}
    end
  end

  defp top_active_matches_from_source(filters) do
    case analytics_summary_source() do
      :neo4j ->
        case top_active_matches_from_neo4j(filters) do
          {:ok, payload} -> {:ok, payload}
          {:error, _} -> {:ok, top_active_matches_from_postgres(filters)}
        end

      _ ->
        {:ok, top_active_matches_from_postgres(filters)}
    end
  end

  defp actor_role_activity_from_source(filters) do
    case analytics_summary_source() do
      :neo4j ->
        case actor_role_activity_from_neo4j(filters) do
          {:ok, payload} -> {:ok, payload}
          {:error, _} -> {:ok, actor_role_activity_from_postgres(filters)}
        end

      _ ->
        {:ok, actor_role_activity_from_postgres(filters)}
    end
  end

  defp match_summary_from_postgres(filters, source) do
    base_query = scoped_domain_events_query(filters)

    total_events = Repo.aggregate(base_query, :count, :id)

    processed_events =
      base_query
      |> where([event], not is_nil(event.processed_at))
      |> Repo.aggregate(:count, :id)

    transition_events =
      base_query
      |> where([event], event.event_type == "match.transitioned")
      |> Repo.aggregate(:count, :id)

    score_events =
      base_query
      |> where([event], event.event_type == "match.score_recorded")
      |> Repo.aggregate(:count, :id)

    event_type_breakdown_query =
      base_query
      |> exclude(:order_by)
      |> exclude(:limit)
      |> exclude(:offset)

    event_type_breakdown =
      event_type_breakdown_query
      |> group_by([event], event.event_type)
      |> select([event], %{event_type: event.event_type, count: count(event.id)})
      |> order_by([event], asc: event.event_type)
      |> Repo.all()

    summary_payload(
      filters,
      source,
      %{
        total_events: total_events,
        processed_events: processed_events,
        unprocessed_events: total_events - processed_events,
        transition_events: transition_events,
        score_events: score_events
      },
      event_type_breakdown
    )
  end

  defp match_summary_from_neo4j(filters) do
    neo4j_client = default_neo4j_client()
    params = cypher_params(filters)
    query_opts = [query_timeout_ms: 10_000]

    with {:ok, [kpi_row | _]} <- neo4j_client.query(kpi_query(), params, query_opts),
         {:ok, breakdown_rows} <- neo4j_client.query(breakdown_query(), params, query_opts) do
      total_events = to_int(kpi_row["total_events"])
      transition_events = to_int(kpi_row["transition_events"])
      score_events = to_int(kpi_row["score_events"])

      # Neo4j only contains projected events, so processed == total in this read model.
      processed_events = total_events
      unprocessed_events = 0

      event_type_breakdown =
        breakdown_rows
        |> Enum.map(fn row ->
          %{
            event_type: row["event_type"],
            count: to_int(row["count"])
          }
        end)
        |> Enum.filter(fn row -> is_binary(row.event_type) end)

      {:ok,
       summary_payload(
         filters,
         "neo4j",
         %{
           total_events: total_events,
           processed_events: processed_events,
           unprocessed_events: unprocessed_events,
           transition_events: transition_events,
           score_events: score_events
         },
         event_type_breakdown
       )}
    end
  end

  defp summary_payload(filters, source, kpis, event_type_breakdown) do
    %{
      scope: %{
        tournament_id: filters.tournament_id,
        division_id: filters.division_id,
        from: filters.from,
        to: filters.to
      },
      pagination: %{limit: filters.limit, offset: filters.offset},
      data_source: source,
      kpis: kpis,
      event_type_breakdown: event_type_breakdown
    }
  end

  defp kpi_query do
    """
    MATCH (e:DomainEvent)-[:APPLIES_TO]->(m:Match)
    WHERE m.tournament_id = $tournament_id
      AND ($division_id IS NULL OR m.division_id = $division_id)
      AND ($from IS NULL OR e.occurred_at >= datetime($from))
      AND ($to IS NULL OR e.occurred_at <= datetime($to))
    WITH e
    ORDER BY e.occurred_at ASC, e.id ASC
    SKIP $offset
    LIMIT $limit
    RETURN
      count(e) AS total_events,
      sum(CASE WHEN e.type = 'match.transitioned' THEN 1 ELSE 0 END) AS transition_events,
      sum(CASE WHEN e.type = 'match.score_recorded' THEN 1 ELSE 0 END) AS score_events
    """
  end

  defp dashboard_event_feed_query do
    """
    MATCH (e:DomainEvent)-[:APPLIES_TO]->(m:Match)
    WHERE m.tournament_id = $tournament_id
      AND ($division_id IS NULL OR m.division_id = $division_id)
      AND ($from IS NULL OR e.occurred_at >= datetime($from))
      AND ($to IS NULL OR e.occurred_at <= datetime($to))
    RETURN
      e.id AS event_id,
      e.type AS event_type,
      e.occurred_at AS occurred_at,
      e.actor_role AS actor_role,
      m.id AS match_id,
      m.state AS match_state,
      m.last_score_type AS last_score_type,
      m.last_score_side AS last_score_side
    ORDER BY e.occurred_at DESC
    SKIP $offset
    LIMIT $limit
    """
  end

  defp match_state_overview_query do
    """
    MATCH (m:Match)
    WHERE m.tournament_id = $tournament_id
      AND ($division_id IS NULL OR m.division_id = $division_id)
    RETURN coalesce(m.state, 'unknown') AS state, count(m) AS count
    ORDER BY state ASC
    """
  end

  defp breakdown_query do
    """
    MATCH (e:DomainEvent)-[:APPLIES_TO]->(m:Match)
    WHERE m.tournament_id = $tournament_id
      AND ($division_id IS NULL OR m.division_id = $division_id)
      AND ($from IS NULL OR e.occurred_at >= datetime($from))
      AND ($to IS NULL OR e.occurred_at <= datetime($to))
    WITH e
    ORDER BY e.occurred_at ASC, e.id ASC
    SKIP $offset
    LIMIT $limit
    RETURN e.type AS event_type, count(e) AS count
    ORDER BY event_type ASC
    """
  end

  defp throughput_trend_query do
    """
    MATCH (e:DomainEvent)-[:APPLIES_TO]->(m:Match)
    WHERE m.tournament_id = $tournament_id
      AND ($division_id IS NULL OR m.division_id = $division_id)
      AND ($from IS NULL OR e.occurred_at >= datetime($from))
      AND ($to IS NULL OR e.occurred_at <= datetime($to))
    WITH datetime.truncate('hour', e.occurred_at) AS bucket_start, e
    RETURN
      bucket_start AS bucket_start,
      count(e) AS total_events,
      sum(CASE WHEN e.type = 'match.transitioned' THEN 1 ELSE 0 END) AS transition_events,
      sum(CASE WHEN e.type = 'match.score_recorded' THEN 1 ELSE 0 END) AS score_events
    ORDER BY bucket_start ASC
    LIMIT 48
    """
  end

  defp top_active_matches_query do
    """
    MATCH (e:DomainEvent)-[:APPLIES_TO]->(m:Match)
    WHERE m.tournament_id = $tournament_id
      AND ($division_id IS NULL OR m.division_id = $division_id)
      AND ($from IS NULL OR e.occurred_at >= datetime($from))
      AND ($to IS NULL OR e.occurred_at <= datetime($to))
    RETURN m.id AS match_id, count(e) AS event_count
    ORDER BY event_count DESC, match_id ASC
    LIMIT 5
    """
  end

  defp actor_role_activity_query do
    """
    MATCH (e:DomainEvent)-[:APPLIES_TO]->(m:Match)
    WHERE m.tournament_id = $tournament_id
      AND ($division_id IS NULL OR m.division_id = $division_id)
      AND ($from IS NULL OR e.occurred_at >= datetime($from))
      AND ($to IS NULL OR e.occurred_at <= datetime($to))
    RETURN coalesce(e.actor_role, 'unknown') AS actor_role, count(e) AS event_count
    ORDER BY event_count DESC, actor_role ASC
    LIMIT 10
    """
  end

  defp cypher_params(filters) do
    %{
      tournament_id: filters.tournament_id,
      division_id: filters.division_id,
      from: if(filters.from, do: DateTime.to_iso8601(filters.from), else: nil),
      to: if(filters.to, do: DateTime.to_iso8601(filters.to), else: nil),
      limit: filters.limit,
      offset: filters.offset
    }
  end

  defp dashboard_event_feed_from_neo4j(filters) do
    neo4j_client = default_neo4j_client()
    params = cypher_params(filters)

    with {:ok, rows} <-
           neo4j_client.query(dashboard_event_feed_query(), params, query_timeout_ms: 10_000) do
      events =
        rows
        |> Enum.map(fn row ->
          %{
            event_id: row["event_id"],
            event_type: row["event_type"],
            occurred_at: row["occurred_at"],
            actor_role: row["actor_role"],
            match_id: row["match_id"],
            match_state: row["match_state"],
            last_score_type: row["last_score_type"],
            last_score_side: row["last_score_side"]
          }
        end)

      {:ok,
       %{
         scope: %{
           tournament_id: filters.tournament_id,
           division_id: filters.division_id,
           from: filters.from,
           to: filters.to
         },
         pagination: %{limit: filters.limit, offset: filters.offset},
         data_source: "neo4j",
         events: events
       }}
    end
  end

  defp throughput_trend_from_neo4j(filters) do
    neo4j_client = default_neo4j_client()
    params = cypher_params(filters)

    with {:ok, rows} <-
           neo4j_client.query(throughput_trend_query(), params, query_timeout_ms: 10_000) do
      {:ok,
       Enum.map(rows, fn row ->
         %{
           bucket_start: normalize_datetime(row["bucket_start"]),
           total_events: to_int(row["total_events"]),
           transition_events: to_int(row["transition_events"]),
           score_events: to_int(row["score_events"])
         }
       end)}
    end
  end

  defp top_active_matches_from_neo4j(filters) do
    neo4j_client = default_neo4j_client()
    params = cypher_params(filters)

    with {:ok, rows} <-
           neo4j_client.query(top_active_matches_query(), params, query_timeout_ms: 10_000) do
      {:ok,
       Enum.map(rows, fn row ->
         %{
           match_id: row["match_id"],
           event_count: to_int(row["event_count"])
         }
       end)}
    end
  end

  defp actor_role_activity_from_neo4j(filters) do
    neo4j_client = default_neo4j_client()
    params = cypher_params(filters)

    with {:ok, rows} <-
           neo4j_client.query(actor_role_activity_query(), params, query_timeout_ms: 10_000) do
      {:ok,
       Enum.map(rows, fn row ->
         %{
           actor_role: row["actor_role"] || "unknown",
           event_count: to_int(row["event_count"])
         }
       end)}
    end
  end

  defp dashboard_event_feed_from_postgres(filters, source) do
    events =
      DomainEvent
      |> where([event], event.aggregate_type == "match")
      |> where(
        [event],
        fragment("?->>'tournament_id' = ?", event.payload, ^filters.tournament_id)
      )
      |> maybe_filter_division(filters.division_id)
      |> maybe_filter_from(filters.from)
      |> maybe_filter_to(filters.to)
      |> order_by([event], desc: event.occurred_at, desc: event.inserted_at)
      |> limit(^filters.limit)
      |> offset(^filters.offset)
      |> Repo.all()
      |> Enum.map(fn event ->
        %{
          event_id: event.id,
          event_type: event.event_type,
          occurred_at: event.occurred_at,
          actor_role: event.actor_role,
          match_id: event.aggregate_id,
          match_state: event.payload["to_state"],
          last_score_type: event.payload["score_type"],
          last_score_side: event.payload["side"]
        }
      end)

    %{
      scope: %{
        tournament_id: filters.tournament_id,
        division_id: filters.division_id,
        from: filters.from,
        to: filters.to
      },
      pagination: %{limit: filters.limit, offset: filters.offset},
      data_source: source,
      events: events
    }
  end

  defp match_state_overview_from_neo4j(filters) do
    neo4j_client = default_neo4j_client()
    params = cypher_params(filters)

    with {:ok, rows} <-
           neo4j_client.query(match_state_overview_query(), params, query_timeout_ms: 10_000) do
      state_counts =
        rows
        |> Enum.map(fn row ->
          %{state: row["state"] || "unknown", count: to_int(row["count"])}
        end)

      {:ok,
       %{
         scope: %{tournament_id: filters.tournament_id, division_id: filters.division_id},
         data_source: "neo4j",
         state_counts: state_counts
       }}
    end
  end

  defp match_state_overview_from_postgres(filters, source) do
    latest_transition_states =
      DomainEvent
      |> where([event], event.aggregate_type == "match")
      |> where([event], event.event_type == "match.transitioned")
      |> where(
        [event],
        fragment("?->>'tournament_id' = ?", event.payload, ^filters.tournament_id)
      )
      |> maybe_filter_division(filters.division_id)
      |> order_by([event],
        asc: event.aggregate_id,
        desc: event.occurred_at,
        desc: event.inserted_at
      )
      |> distinct([event], event.aggregate_id)
      |> select([event], fragment("?->>'to_state'", event.payload))
      |> Repo.all()

    state_counts =
      latest_transition_states
      |> Enum.map(&(&1 || "unknown"))
      |> Enum.frequencies()
      |> Enum.map(fn {state, count} -> %{state: state, count: count} end)
      |> Enum.sort_by(& &1.state)

    %{
      scope: %{tournament_id: filters.tournament_id, division_id: filters.division_id},
      data_source: source,
      state_counts: state_counts
    }
  end

  defp throughput_trend_from_postgres(filters) do
    scoped_domain_events_without_pagination(filters)
    |> group_by([event], fragment("date_trunc('hour', ?)", event.occurred_at))
    |> select([event], %{
      bucket_start: fragment("date_trunc('hour', ?)", event.occurred_at),
      total_events: count(event.id),
      transition_events:
        sum(
          fragment(
            "CASE WHEN ? = 'match.transitioned' THEN 1 ELSE 0 END",
            event.event_type
          )
        ),
      score_events:
        sum(
          fragment(
            "CASE WHEN ? = 'match.score_recorded' THEN 1 ELSE 0 END",
            event.event_type
          )
        )
    })
    |> order_by([event], asc: fragment("date_trunc('hour', ?)", event.occurred_at))
    |> limit(48)
    |> Repo.all()
    |> Enum.map(fn row ->
      %{
        bucket_start: normalize_datetime(row.bucket_start),
        total_events: to_int(row.total_events),
        transition_events: to_int(row.transition_events),
        score_events: to_int(row.score_events)
      }
    end)
  end

  defp top_active_matches_from_postgres(filters) do
    scoped_domain_events_without_pagination(filters)
    |> group_by([event], event.aggregate_id)
    |> select([event], %{match_id: event.aggregate_id, event_count: count(event.id)})
    |> order_by([event], desc: count(event.id), asc: event.aggregate_id)
    |> limit(5)
    |> Repo.all()
    |> Enum.map(fn row ->
      %{match_id: row.match_id, event_count: to_int(row.event_count)}
    end)
  end

  defp actor_role_activity_from_postgres(filters) do
    scoped_domain_events_without_pagination(filters)
    |> group_by([event], event.actor_role)
    |> select([event], %{actor_role: event.actor_role, event_count: count(event.id)})
    |> order_by([event], desc: count(event.id), asc: event.actor_role)
    |> limit(10)
    |> Repo.all()
    |> Enum.map(fn row ->
      %{
        actor_role: row.actor_role || "unknown",
        event_count: to_int(row.event_count)
      }
    end)
  end

  defp to_int(value) when is_integer(value), do: value
  defp to_int(value) when is_float(value), do: trunc(value)

  defp to_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {number, ""} -> number
      _ -> 0
    end
  end

  defp to_int(_), do: 0

  defp normalize_datetime(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)

  defp normalize_datetime(%NaiveDateTime{} = datetime),
    do: NaiveDateTime.to_iso8601(datetime) <> "Z"

  defp normalize_datetime(value) when is_binary(value), do: value
  defp normalize_datetime(value), do: to_string(value)

  defp analytics_summary_source do
    Application.get_env(:zanshin_api, :analytics_summary_source, :postgres)
  end

  defp default_neo4j_client do
    Application.get_env(:zanshin_api, :neo4j_client, ZanshinApi.Analytics.Neo4jClient.Noop)
  end

  defp normalize_filters(params) do
    tournament_id = Map.get(params, "tournament_id") || Map.get(params, :tournament_id)

    if is_nil(tournament_id) do
      {:error, :tournament_id_required}
    else
      division_id = Map.get(params, "division_id") || Map.get(params, :division_id)

      limit =
        parse_positive_integer(
          Map.get(params, "limit") || Map.get(params, :limit),
          @default_limit
        )

      offset =
        parse_non_negative_integer(Map.get(params, "offset") || Map.get(params, :offset), 0)

      with {:ok, from} <-
             parse_optional_datetime(Map.get(params, "from") || Map.get(params, :from)),
           {:ok, to} <- parse_optional_datetime(Map.get(params, "to") || Map.get(params, :to)),
           :ok <- validate_time_window(from, to) do
        {:ok,
         %{
           tournament_id: tournament_id,
           division_id: division_id,
           from: from,
           to: to,
           limit: min(limit, @max_limit),
           offset: offset
         }}
      else
        {:error, :invalid_datetime} -> {:error, :invalid_datetime_filter}
        {:error, :invalid_time_window} -> {:error, :invalid_time_window}
      end
    end
  end

  defp scoped_domain_events_query(filters) do
    DomainEvent
    |> where([event], event.aggregate_type == "match")
    |> where([event], fragment("?->>'tournament_id' = ?", event.payload, ^filters.tournament_id))
    |> maybe_filter_division(filters.division_id)
    |> maybe_filter_from(filters.from)
    |> maybe_filter_to(filters.to)
    |> order_by([event], asc: event.inserted_at)
    |> limit(^filters.limit)
    |> offset(^filters.offset)
  end

  defp scoped_domain_events_without_pagination(filters) do
    DomainEvent
    |> where([event], event.aggregate_type == "match")
    |> where([event], fragment("?->>'tournament_id' = ?", event.payload, ^filters.tournament_id))
    |> maybe_filter_division(filters.division_id)
    |> maybe_filter_from(filters.from)
    |> maybe_filter_to(filters.to)
  end

  defp maybe_filter_division(query, nil), do: query

  defp maybe_filter_division(query, division_id) do
    where(query, [event], fragment("?->>'division_id' = ?", event.payload, ^division_id))
  end

  defp maybe_filter_from(query, nil), do: query
  defp maybe_filter_from(query, from), do: where(query, [event], event.occurred_at >= ^from)

  defp maybe_filter_to(query, nil), do: query
  defp maybe_filter_to(query, to), do: where(query, [event], event.occurred_at <= ^to)

  defp parse_optional_datetime(nil), do: {:ok, nil}
  defp parse_optional_datetime(""), do: {:ok, nil}

  defp parse_optional_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, parsed, _offset} -> {:ok, parsed}
      _ -> {:error, :invalid_datetime}
    end
  end

  defp parse_optional_datetime(_), do: {:error, :invalid_datetime}

  defp validate_time_window(nil, nil), do: :ok
  defp validate_time_window(_from, nil), do: :ok
  defp validate_time_window(nil, _to), do: :ok

  defp validate_time_window(from, to) do
    case DateTime.compare(from, to) do
      comparison when comparison in [:lt, :eq] -> :ok
      :gt -> {:error, :invalid_time_window}
    end
  end

  defp parse_positive_integer(nil, default), do: default
  defp parse_positive_integer("", default), do: default

  defp parse_positive_integer(value, _default) when is_integer(value) and value > 0, do: value

  defp parse_positive_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {number, ""} when number > 0 -> number
      _ -> default
    end
  end

  defp parse_positive_integer(_value, default), do: default

  defp parse_non_negative_integer(nil, default), do: default
  defp parse_non_negative_integer("", default), do: default

  defp parse_non_negative_integer(value, _default) when is_integer(value) and value >= 0,
    do: value

  defp parse_non_negative_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {number, ""} when number >= 0 -> number
      _ -> default
    end
  end

  defp parse_non_negative_integer(_value, default), do: default
end
