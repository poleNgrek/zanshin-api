import { Alert, MenuItem, Stack, TextField } from "@mui/material";
import { useLoaderData } from "@remix-run/react";
import { useEffect, useMemo, useRef, useState } from "react";

import { ApiError, fetchMatchEventsSnapshot, fetchWithSchema } from "@zanshin/api";
import { InfoAlertList, PageTitle, SectionCard } from "@zanshin/components";
import {
    CompetitorListResponseSchema,
    DivisionListResponseSchema,
    MatchListResponseSchema,
    TournamentListResponseSchema
} from "@zanshin/schemas";
import { type Competitor, type Division, type Match, type Tournament } from "@zanshin/types";
import { applyMatchRealtimeEvents } from "@zanshin/utils/realtime_updates";

type MatchLoaderData = {
  matches: Match[];
  tournaments: Tournament[];
  divisions: Division[];
  competitors: Competitor[];
};

export async function clientLoader(): Promise<MatchLoaderData> {
  const [matchResponse, tournamentResponse, competitorResponse] = await Promise.all([
    fetchWithSchema("/api/v1/matches", MatchListResponseSchema),
    fetchWithSchema("/api/v1/tournaments", TournamentListResponseSchema),
    fetchWithSchema("/api/v1/competitors", CompetitorListResponseSchema)
  ]);

  const tournamentIdsInMatches = Array.from(new Set(matchResponse.data.map((match) => match.tournament_id)));
  const divisionResponses = await Promise.all(
    tournamentIdsInMatches.map((tournamentId) =>
      fetchWithSchema(`/api/v1/divisions?tournament_id=${encodeURIComponent(tournamentId)}`, DivisionListResponseSchema)
    )
  );
  const divisions = divisionResponses.flatMap((response) => response.data);

  return {
    matches: matchResponse.data,
    tournaments: tournamentResponse.data,
    divisions,
    competitors: competitorResponse.data
  };
}

export default function MatchesRoute() {
  const { matches, tournaments, divisions, competitors } = useLoaderData<typeof clientLoader>();
  const [liveMatches, setLiveMatches] = useState(matches);
  const [selectedTournamentId, setSelectedTournamentId] = useState("all");
  const [selectedDivisionId, setSelectedDivisionId] = useState("all");
  const [liveError, setLiveError] = useState<string | null>(null);
  const [liveEnabled, setLiveEnabled] = useState(true);
  const [lastUpdatedAt, setLastUpdatedAt] = useState<Date | null>(null);
  const sinceIdRef = useRef<string | undefined>(undefined);

  useEffect(() => {
    sinceIdRef.current = undefined;
  }, [selectedTournamentId]);

  const competitorById = useMemo(
    () => new Map(competitors.map((competitor) => [competitor.id, competitor.display_name])),
    [competitors]
  );

  const tournamentsInMatches = useMemo(() => {
    const tournamentIds = new Set(liveMatches.map((match) => match.tournament_id));
    return tournaments.filter((tournament) => tournamentIds.has(tournament.id));
  }, [liveMatches, tournaments]);

  const divisionsInScope = useMemo(() => {
    const divisionIds = new Set(
      liveMatches
        .filter((match) => selectedTournamentId === "all" || match.tournament_id === selectedTournamentId)
        .map((match) => match.division_id)
    );
    return divisions.filter((division) => divisionIds.has(division.id));
  }, [divisions, liveMatches, selectedTournamentId]);

  const filteredMatches = useMemo(
    () =>
      liveMatches.filter((match) => {
        if (selectedTournamentId !== "all" && match.tournament_id !== selectedTournamentId) return false;
        if (selectedDivisionId !== "all" && match.division_id !== selectedDivisionId) return false;
        return true;
      }),
    [liveMatches, selectedDivisionId, selectedTournamentId]
  );

  useEffect(() => {
    if (!liveEnabled || selectedTournamentId === "all") {
      return;
    }

    let cancelled = false;

    async function pollRealtime() {
      try {
        const snapshot = await fetchMatchEventsSnapshot({
          tournament_id: selectedTournamentId,
          since_id: sinceIdRef.current,
          limit: 50
        });

        if (cancelled) {
          return;
        }

        if (snapshot.events.length > 0) {
          sinceIdRef.current = snapshot.events[snapshot.events.length - 1]?.id;
          setLiveMatches((currentMatches) => applyMatchRealtimeEvents(currentMatches, snapshot.events));
          setLastUpdatedAt(new Date());
        }

        setLiveError(null);
      } catch (err) {
        if (!cancelled) {
          const message = err instanceof ApiError ? err.message : "live_match_refresh_failed";
          setLiveError(message);
        }
      }
    }

    void pollRealtime();
    const interval = window.setInterval(() => {
      void pollRealtime();
    }, 5000);

    return () => {
      cancelled = true;
      window.clearInterval(interval);
    };
  }, [liveEnabled, selectedTournamentId]);

  function handleTournamentChange(nextTournamentId: string) {
    setSelectedTournamentId(nextTournamentId);
    if (nextTournamentId === "all") {
      setSelectedDivisionId("all");
      return;
    }

    const divisionStillValid = divisionsInScope.some((division) => division.id === selectedDivisionId);
    if (!divisionStillValid) {
      setSelectedDivisionId("all");
    }
  }

  return (
    <Stack spacing={2}>
      <PageTitle title="Match List" description="Public consumer view of currently recorded matches." />
      <SectionCard title="Filters and Live Status">
        <Stack spacing={1.5}>
          <Alert severity={liveError ? "warning" : "info"}>
            Live updates: {liveEnabled ? "on" : "off"}
            {selectedTournamentId === "all" ? " (select a tournament to subscribe)" : ""}
            {lastUpdatedAt ? ` - last sync ${lastUpdatedAt.toLocaleTimeString()}` : ""}
            {liveError ? ` - ${liveError}` : ""}
          </Alert>

          <Stack direction={{ xs: "column", md: "row" }} spacing={1}>
            <TextField
              select
              label="Tournament"
              value={selectedTournamentId}
              onChange={(event) => handleTournamentChange(event.target.value)}
              sx={{ minWidth: 300 }}
            >
              <MenuItem value="all">All tournaments</MenuItem>
              {tournamentsInMatches.map((tournament) => (
                <MenuItem key={tournament.id} value={tournament.id}>
                  {tournament.name}
                </MenuItem>
              ))}
            </TextField>
            <TextField
              select
              label="Division"
              value={selectedDivisionId}
              onChange={(event) => setSelectedDivisionId(event.target.value)}
              sx={{ minWidth: 300 }}
            >
              <MenuItem value="all">All divisions</MenuItem>
              {divisionsInScope.map((division) => (
                <MenuItem key={division.id} value={division.id}>
                  {division.name}
                </MenuItem>
              ))}
            </TextField>
            <TextField
              select
              label="Live Refresh"
              value={liveEnabled ? "on" : "off"}
              onChange={(event) => setLiveEnabled(event.target.value === "on")}
              sx={{ minWidth: 220 }}
            >
              <MenuItem value="on">Enabled</MenuItem>
              <MenuItem value="off">Disabled</MenuItem>
            </TextField>
          </Stack>
        </Stack>
      </SectionCard>

      {filteredMatches.length === 0 ? <Alert severity="info">No matches found for this filter.</Alert> : null}

      <SectionCard title="Matches">
        <InfoAlertList
          items={filteredMatches.map((match) => {
            const akaName = competitorById.get(match.aka_competitor_id) ?? match.aka_competitor_id;
            const shiroName = competitorById.get(match.shiro_competitor_id) ?? match.shiro_competitor_id;
            return {
              id: match.id,
              text: `${akaName} vs ${shiroName} - ${match.state} (${match.id})`
            };
          })}
        />
      </SectionCard>
    </Stack>
  );
}
