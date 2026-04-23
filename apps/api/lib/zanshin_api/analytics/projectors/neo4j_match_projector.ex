defmodule ZanshinApi.Analytics.Projectors.Neo4jMatchProjector do
  @moduledoc """
  Projects match lifecycle and score domain events into Neo4j.
  """

  @behaviour ZanshinApi.Analytics.Projector

  alias ZanshinApi.Events.DomainEvent

  @impl true
  def project(%DomainEvent{event_type: "match.transitioned"} = event, opts) do
    params = %{
      event_id: event.id,
      match_id: event.aggregate_id,
      event_type: event.event_type,
      tournament_id: event.payload["tournament_id"],
      division_id: event.payload["division_id"],
      from_state: event.payload["from_state"],
      to_state: event.payload["to_state"],
      transition_event: event.payload["event"],
      actor_role: event.actor_role,
      occurred_at: DateTime.to_iso8601(event.occurred_at)
    }

    execute(statement_for_transition(), params, opts)
  end

  def project(%DomainEvent{event_type: "match.score_recorded"} = event, opts) do
    params = %{
      event_id: event.id,
      match_id: event.aggregate_id,
      event_type: event.event_type,
      tournament_id: event.payload["tournament_id"],
      division_id: event.payload["division_id"],
      score_event_id: event.payload["score_event_id"],
      score_type: event.payload["score_type"],
      side: event.payload["side"],
      target: event.payload["target"],
      actor_role: event.actor_role,
      occurred_at: DateTime.to_iso8601(event.occurred_at)
    }

    execute(statement_for_score(), params, opts)
  end

  def project(_event, _opts), do: :ok

  defp execute(cypher, params, opts) do
    client = Keyword.get(opts, :neo4j_client, default_neo4j_client())
    client.execute(cypher, params, opts)
  end

  defp default_neo4j_client do
    Application.get_env(
      :zanshin_api,
      :neo4j_client,
      ZanshinApi.Analytics.Neo4jClient.Noop
    )
  end

  defp statement_for_transition do
    """
    MERGE (m:Match {id: $match_id})
    SET m.state = $to_state,
        m.tournament_id = $tournament_id,
        m.division_id = $division_id,
        m.updated_at = datetime($occurred_at)
    MERGE (e:DomainEvent {id: $event_id})
    SET e.type = $event_type,
        e.occurred_at = datetime($occurred_at),
        e.actor_role = $actor_role,
        e.transition_event = $transition_event,
        e.from_state = $from_state,
        e.to_state = $to_state
    MERGE (e)-[:APPLIES_TO]->(m)
    """
  end

  defp statement_for_score do
    """
    MERGE (m:Match {id: $match_id})
    SET m.updated_at = datetime($occurred_at),
        m.tournament_id = $tournament_id,
        m.division_id = $division_id,
        m.last_score_type = $score_type,
        m.last_score_side = $side,
        m.last_score_target = $target
    MERGE (e:DomainEvent {id: $event_id})
    SET e.type = $event_type,
        e.occurred_at = datetime($occurred_at),
        e.actor_role = $actor_role,
        e.score_event_id = $score_event_id,
        e.score_type = $score_type,
        e.side = $side,
        e.target = $target
    MERGE (e)-[:APPLIES_TO]->(m)
    """
  end
end
