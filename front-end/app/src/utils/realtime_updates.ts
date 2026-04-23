import type {
  AnalyticsOverview,
  Competitor,
  Division,
  GradingResult,
  GradingSession,
  Match,
  MatchRealtimeEvent,
  Tournament
} from "@zanshin/types";

type AnalyticsScope = {
  divisionId: string;
  fromIso: string;
  toIso: string;
};

export type AdminRealtimeEvent = {
  event: string;
  payload: Record<string, unknown>;
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

export function applyAdminTournamentEvents(
  tournaments: Tournament[],
  events: AdminRealtimeEvent[]
): Tournament[] {
  return events.reduce((current, event) => {
    if (event.event !== "admin_tournament_created") {
      return current;
    }

    const tournamentId = stringValue(event.payload.tournament_id);
    const name = stringValue(event.payload.name);

    if (!tournamentId || !name) {
      return current;
    }

    if (current.some((tournament) => tournament.id === tournamentId)) {
      return current;
    }

    return [{ id: tournamentId, name, starts_on: null }, ...current];
  }, tournaments);
}

export function applyAdminDivisionEvents(
  divisions: Division[],
  events: AdminRealtimeEvent[],
  tournamentId: string
): Division[] {
  return events.reduce((current, event) => {
    if (event.event !== "admin_division_created") {
      return current;
    }

    const nextTournamentId = stringValue(event.payload.tournament_id);
    const divisionId = stringValue(event.payload.division_id);
    const name = stringValue(event.payload.name);

    if (!nextTournamentId || !divisionId || !name || nextTournamentId !== tournamentId) {
      return current;
    }

    if (current.some((division) => division.id === divisionId)) {
      return current;
    }

    return [...current, { id: divisionId, tournament_id: nextTournamentId, name, format: "bracket" }].sort((a, b) =>
      a.name.localeCompare(b.name)
    );
  }, divisions);
}

export function applyAdminSessionEvents(
  sessions: GradingSession[],
  events: AdminRealtimeEvent[],
  tournamentId: string
): GradingSession[] {
  return events.reduce((current, event) => {
    if (event.event !== "admin_grading_session_created") {
      return current;
    }

    const nextTournamentId = stringValue(event.payload.tournament_id);
    const sessionId = stringValue(event.payload.grading_session_id);
    const name = stringValue(event.payload.session_name);

    if (!nextTournamentId || !sessionId || !name || nextTournamentId !== tournamentId) {
      return current;
    }

    if (current.some((session) => session.id === sessionId)) {
      return current;
    }

    return [{ id: sessionId, tournament_id: nextTournamentId, name, held_on: null, written_required: true }, ...current];
  }, sessions);
}

export function applyAdminCompetitorEvents(
  competitors: Competitor[],
  events: AdminRealtimeEvent[]
): Competitor[] {
  return events.reduce((current, event) => {
    if (event.event !== "admin_competitor_created") {
      return current;
    }

    const competitorId = stringValue(event.payload.competitor_id);
    const displayName = stringValue(event.payload.display_name);

    if (!competitorId || !displayName) {
      return current;
    }

    if (current.some((competitor) => competitor.id === competitorId)) {
      return current;
    }

    return [...current, { id: competitorId, display_name: displayName, federation_id: null }].sort((a, b) =>
      a.display_name.localeCompare(b.display_name)
    );
  }, competitors);
}

export function applyAdminGradingResultEvents(
  results: GradingResult[],
  events: AdminRealtimeEvent[],
  selectedSessionId: string
): { results: GradingResult[]; shouldReload: boolean } {
  let nextResults = results;
  let shouldReload = false;

  for (const event of events) {
    const eventSessionId = stringValue(event.payload.grading_session_id);
    if (!eventSessionId || eventSessionId !== selectedSessionId) {
      continue;
    }

    if (event.event === "admin_grading_result_created") {
      shouldReload = true;
      continue;
    }

    const resultId = stringValue(event.payload.grading_result_id);
    if (!resultId) {
      continue;
    }

    if (event.event === "admin_grading_result_computed") {
      const finalResult = stringValue(event.payload.final_result);
      if (finalResult) {
        nextResults = nextResults.map((result) =>
          result.id === resultId ? { ...result, final_result: finalResult } : result
        );
      } else {
        shouldReload = true;
      }
      continue;
    }

    if (event.event === "admin_grading_result_finalized") {
      const occurredAt = stringValue(event.payload.occurred_at) ?? new Date().toISOString();
      nextResults = nextResults.map((result) =>
        result.id === resultId ? { ...result, locked_at: occurredAt } : result
      );
    }
  }

  return { results: nextResults, shouldReload };
}
