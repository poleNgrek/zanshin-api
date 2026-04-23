import type { AnalyticsOverview, Match, MatchRealtimeEvent } from "@zanshin/types";

type AnalyticsScope = {
  divisionId: string;
  fromIso: string;
  toIso: string;
};

export function applyMatchRealtimeEvents(matches: Match[], events: MatchRealtimeEvent[]): Match[] {
  return events.reduce((currentMatches, event) => {
    if (event.event_type === "match.transitioned") {
      const payloadMatchId = stringValue(event.payload.match_id);
      const nextState = stringValue(event.payload.to_state);

      if (!payloadMatchId || !nextState) {
        return currentMatches;
      }

      return currentMatches.map((match) =>
        match.id === payloadMatchId ? { ...match, state: nextState } : match
      );
    }

    if (event.event_type === "match.created") {
      const createdMatch = toMatchFromCreateEvent(event);
      if (!createdMatch) {
        return currentMatches;
      }

      const alreadyPresent = currentMatches.some((match) => match.id === createdMatch.id);
      if (alreadyPresent) {
        return currentMatches;
      }

      return [createdMatch, ...currentMatches];
    }

    return currentMatches;
  }, matches);
}

export function applyEventsToAnalyticsOverview(
  overview: AnalyticsOverview,
  events: MatchRealtimeEvent[],
  scope: AnalyticsScope
): AnalyticsOverview {
  const next = structuredClone(overview);
  const maxRecent = Math.max(next.recent_events.length, 10);
  const maxTopMatches = Math.max(next.insights.top_active_matches.length, 5);

  for (const event of events) {
    if (!eventInScope(event, scope)) {
      continue;
    }

    next.summary.kpis.total_events += 1;
    bumpBreakdown(next, event.event_type);
    bumpRecentEvents(next, event, maxRecent);
    bumpTopActiveMatches(next, event.aggregate_id, maxTopMatches);
    bumpActorRole(next, event.actor_role ?? "unknown");
    bumpThroughput(next, event);

    if (event.event_type === "match.transitioned") {
      next.summary.kpis.transition_events += 1;
      bumpStateCount(next, stringValue(event.payload.to_state));
    } else if (event.event_type === "match.score_recorded") {
      next.summary.kpis.score_events += 1;
    }
  }

  return next;
}

function toMatchFromCreateEvent(event: MatchRealtimeEvent): Match | null {
  const matchId = stringValue(event.payload.match_id);
  const tournamentId = stringValue(event.payload.tournament_id);
  const divisionId = stringValue(event.payload.division_id);
  const akaCompetitorId = stringValue(event.payload.aka_competitor_id);
  const shiroCompetitorId = stringValue(event.payload.shiro_competitor_id);
  const state = stringValue(event.payload.state);

  if (!matchId || !tournamentId || !divisionId || !akaCompetitorId || !shiroCompetitorId || !state) {
    return null;
  }

  return {
    id: matchId,
    tournament_id: tournamentId,
    division_id: divisionId,
    aka_competitor_id: akaCompetitorId,
    shiro_competitor_id: shiroCompetitorId,
    state,
    inserted_at: event.occurred_at
  };
}

function eventInScope(event: MatchRealtimeEvent, scope: AnalyticsScope): boolean {
  const payloadDivisionId = stringValue(event.payload.division_id);
  if (scope.divisionId && payloadDivisionId !== scope.divisionId) {
    return false;
  }

  const occurredAtMs = Date.parse(event.occurred_at);
  if (Number.isNaN(occurredAtMs)) {
    return false;
  }

  if (scope.fromIso) {
    const fromMs = Date.parse(scope.fromIso);
    if (!Number.isNaN(fromMs) && occurredAtMs < fromMs) {
      return false;
    }
  }

  if (scope.toIso) {
    const toMs = Date.parse(scope.toIso);
    if (!Number.isNaN(toMs) && occurredAtMs > toMs) {
      return false;
    }
  }

  return true;
}

function bumpBreakdown(overview: AnalyticsOverview, eventType: string): void {
  const item = overview.summary.event_type_breakdown.find((entry) => entry.event_type === eventType);
  if (item) {
    item.count += 1;
    return;
  }

  overview.summary.event_type_breakdown.push({ event_type: eventType, count: 1 });
}

function bumpRecentEvents(overview: AnalyticsOverview, event: MatchRealtimeEvent, maxRecent: number): void {
  overview.recent_events.unshift({
    event_id: event.id,
    event_type: event.event_type,
    aggregate_id: event.aggregate_id,
    occurred_at: event.occurred_at,
    payload: event.payload
  });

  if (overview.recent_events.length > maxRecent) {
    overview.recent_events = overview.recent_events.slice(0, maxRecent);
  }
}

function bumpTopActiveMatches(overview: AnalyticsOverview, matchId: string, maxTopMatches: number): void {
  const existing = overview.insights.top_active_matches.find((item) => item.match_id === matchId);

  if (existing) {
    existing.event_count += 1;
  } else {
    overview.insights.top_active_matches.push({ match_id: matchId, event_count: 1 });
  }

  overview.insights.top_active_matches.sort((left, right) => right.event_count - left.event_count);
  overview.insights.top_active_matches = overview.insights.top_active_matches.slice(0, maxTopMatches);
}

function bumpActorRole(overview: AnalyticsOverview, actorRole: string): void {
  const existing = overview.insights.actor_role_activity.find((item) => item.actor_role === actorRole);

  if (existing) {
    existing.event_count += 1;
    return;
  }

  overview.insights.actor_role_activity.push({ actor_role: actorRole, event_count: 1 });
}

function bumpStateCount(overview: AnalyticsOverview, nextState: string | null): void {
  if (!nextState) {
    return;
  }

  const existing = overview.state_overview.state_counts.find((item) => item.state === nextState);
  if (existing) {
    existing.count += 1;
    return;
  }

  overview.state_overview.state_counts.push({ state: nextState, count: 1 });
}

function bumpThroughput(overview: AnalyticsOverview, event: MatchRealtimeEvent): void {
  const bucketStartIso = toHourBucketIso(event.occurred_at);
  if (!bucketStartIso) {
    return;
  }

  const existing = overview.insights.throughput_trend.find((item) => item.bucket_start === bucketStartIso);
  if (existing) {
    existing.total_events += 1;
    if (event.event_type === "match.transitioned") {
      existing.transition_events += 1;
    }
    if (event.event_type === "match.score_recorded") {
      existing.score_events += 1;
    }
    return;
  }

  overview.insights.throughput_trend.push({
    bucket_start: bucketStartIso,
    total_events: 1,
    transition_events: event.event_type === "match.transitioned" ? 1 : 0,
    score_events: event.event_type === "match.score_recorded" ? 1 : 0
  });

  overview.insights.throughput_trend.sort(
    (left, right) => Date.parse(left.bucket_start) - Date.parse(right.bucket_start)
  );
}

function toHourBucketIso(occurredAt: string): string | null {
  const timestamp = Date.parse(occurredAt);
  if (Number.isNaN(timestamp)) {
    return null;
  }

  const date = new Date(timestamp);
  date.setUTCMinutes(0, 0, 0);
  return date.toISOString();
}

function stringValue(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? value : null;
}
