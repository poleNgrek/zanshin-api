import { Alert, MenuItem, Stack, TextField, Typography } from "@mui/material";
import { useLoaderData } from "@remix-run/react";
import { useMemo, useState } from "react";

import { fetchWithSchema } from "~/lib/api/client";
import { type Competitor, competitorListResponseSchema } from "~/lib/schemas/competitors";
import { type Division, divisionListResponseSchema } from "~/lib/schemas/divisions";
import { type Match, matchListResponseSchema } from "~/lib/schemas/matches";
import { type Tournament, tournamentListResponseSchema } from "~/lib/schemas/tournaments";

type MatchLoaderData = {
  matches: Match[];
  tournaments: Tournament[];
  divisions: Division[];
  competitors: Competitor[];
};

export async function clientLoader(): Promise<MatchLoaderData> {
  const [matchResponse, tournamentResponse, competitorResponse] = await Promise.all([
    fetchWithSchema("/api/v1/matches", matchListResponseSchema),
    fetchWithSchema("/api/v1/tournaments", tournamentListResponseSchema),
    fetchWithSchema("/api/v1/competitors", competitorListResponseSchema)
  ]);

  const tournamentIdsInMatches = Array.from(new Set(matchResponse.data.map((match) => match.tournament_id)));
  const divisionResponses = await Promise.all(
    tournamentIdsInMatches.map((tournamentId) =>
      fetchWithSchema(`/api/v1/divisions?tournament_id=${encodeURIComponent(tournamentId)}`, divisionListResponseSchema)
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
  const [selectedTournamentId, setSelectedTournamentId] = useState("all");
  const [selectedDivisionId, setSelectedDivisionId] = useState("all");

  const competitorById = useMemo(
    () => new Map(competitors.map((competitor) => [competitor.id, competitor.display_name])),
    [competitors]
  );

  const tournamentsInMatches = useMemo(() => {
    const tournamentIds = new Set(matches.map((match) => match.tournament_id));
    return tournaments.filter((tournament) => tournamentIds.has(tournament.id));
  }, [matches, tournaments]);

  const divisionsInScope = useMemo(() => {
    const divisionIds = new Set(
      matches
        .filter((match) => selectedTournamentId === "all" || match.tournament_id === selectedTournamentId)
        .map((match) => match.division_id)
    );
    return divisions.filter((division) => divisionIds.has(division.id));
  }, [divisions, matches, selectedTournamentId]);

  const filteredMatches = useMemo(
    () =>
      matches.filter((match) => {
        if (selectedTournamentId !== "all" && match.tournament_id !== selectedTournamentId) return false;
        if (selectedDivisionId !== "all" && match.division_id !== selectedDivisionId) return false;
        return true;
      }),
    [matches, selectedDivisionId, selectedTournamentId]
  );

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
      <Typography variant="h4">Match List</Typography>
      <Typography variant="body1" color="text.secondary">
        Public consumer view of currently recorded matches.
      </Typography>

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
      </Stack>

      {filteredMatches.length === 0 ? <Alert severity="info">No matches found for this filter.</Alert> : null}

      <Stack spacing={1}>
        {filteredMatches.map((match) => {
          const akaName = competitorById.get(match.aka_competitor_id) ?? match.aka_competitor_id;
          const shiroName = competitorById.get(match.shiro_competitor_id) ?? match.shiro_competitor_id;

          return (
            <Alert key={match.id} severity="info">
              {akaName} vs {shiroName} - {match.state} ({match.id})
            </Alert>
          );
        })}
      </Stack>
    </Stack>
  );
}
