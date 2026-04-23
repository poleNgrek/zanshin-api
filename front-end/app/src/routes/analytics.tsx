import { Alert, Button, Grid, MenuItem, Stack, Table, TableBody, TableCell, TableHead, TableRow, TextField, Typography } from "@mui/material";
import { useLoaderData } from "@remix-run/react";
import { useMemo, useState } from "react";

import { ApiError, fetchWithSchema } from "@zanshin/api";
import { PageTitle, SectionCard } from "@zanshin/components";
import {
    AnalyticsOverviewResponseSchema,
    DivisionListResponseSchema,
    TournamentListResponseSchema
} from "@zanshin/schemas";
import { type AnalyticsOverview, type Division, type Tournament } from "@zanshin/types";

type AnalyticsLoaderData = {
  tournaments: Tournament[];
  divisions: Division[];
  initialTournamentId: string;
  initialDivisionId: string;
  initialOverview: AnalyticsOverview | null;
};

export async function clientLoader(): Promise<AnalyticsLoaderData> {
  const tournamentResponse = await fetchWithSchema("/api/v1/tournaments", TournamentListResponseSchema);
  const tournaments = tournamentResponse.data;
  const initialTournamentId = tournaments[0]?.id ?? "";

  if (!initialTournamentId) {
    return {
      tournaments,
      divisions: [],
      initialTournamentId: "",
      initialDivisionId: "",
      initialOverview: null
    };
  }

  const divisionResponse = await fetchWithSchema(
    `/api/v1/divisions?tournament_id=${encodeURIComponent(initialTournamentId)}`,
    DivisionListResponseSchema
  );
  const divisions = divisionResponse.data;
  const initialDivisionId = divisions[0]?.id ?? "";

  const query = new URLSearchParams({
    tournament_id: initialTournamentId,
    ...(initialDivisionId ? { division_id: initialDivisionId } : {}),
    limit: "10"
  });
  const overviewResponse = await fetchWithSchema(
    `/api/v1/analytics/dashboard/overview?${query.toString()}`,
    AnalyticsOverviewResponseSchema
  );

  return {
    tournaments,
    divisions,
    initialTournamentId,
    initialDivisionId,
    initialOverview: overviewResponse.data
  };
}

export default function AnalyticsRoute() {
  const { tournaments, divisions, initialTournamentId, initialDivisionId, initialOverview } =
    useLoaderData<typeof clientLoader>();
  const [selectedTournamentId, setSelectedTournamentId] = useState(initialTournamentId);
  const [selectedDivisionId, setSelectedDivisionId] = useState(initialDivisionId);
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [overview, setOverview] = useState<AnalyticsOverview | null>(initialOverview);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const divisionsInScope = useMemo(() => {
    return divisions.filter((division) => division.tournament_id === selectedTournamentId);
  }, [divisions, selectedTournamentId]);

  const peakTrendBucket = useMemo(() => {
    if (!overview || overview.insights.throughput_trend.length === 0) {
      return null;
    }

    return [...overview.insights.throughput_trend].sort((left, right) => right.total_events - left.total_events)[0];
  }, [overview]);

  async function loadOverview() {
    if (!selectedTournamentId) {
      return;
    }

    setLoading(true);
    try {
      const query = new URLSearchParams({
        tournament_id: selectedTournamentId,
        ...(selectedDivisionId ? { division_id: selectedDivisionId } : {}),
        ...(from ? { from: new Date(from).toISOString() } : {}),
        ...(to ? { to: new Date(to).toISOString() } : {}),
        limit: "10"
      });
      const response = await fetchWithSchema(
        `/api/v1/analytics/dashboard/overview?${query.toString()}`,
        AnalyticsOverviewResponseSchema
      );
      setOverview(response.data);
      setError(null);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_load_analytics_overview";
      setError(message);
    } finally {
      setLoading(false);
    }
  }

  function handleTournamentChange(nextTournamentId: string) {
    setSelectedTournamentId(nextTournamentId);
    const firstDivisionId = divisions.find((division) => division.tournament_id === nextTournamentId)?.id ?? "";
    setSelectedDivisionId(firstDivisionId);
  }

  return (
    <Stack spacing={2}>
      <PageTitle
        title="Analytics Dashboard"
        description="Consolidated view of event volume, lifecycle state mix, and recent match activity from projection-backed analytics."
      />

      {error ? <Alert severity="error">{error}</Alert> : null}
      {tournaments.length === 0 ? <Alert severity="warning">No tournaments available yet.</Alert> : null}

      <Stack direction={{ xs: "column", md: "row" }} spacing={1}>
        <TextField
          select
          label="Tournament"
          value={selectedTournamentId}
          onChange={(event) => handleTournamentChange(event.target.value)}
          sx={{ minWidth: 280 }}
        >
          {tournaments.map((item) => (
            <MenuItem key={item.id} value={item.id}>
              {item.name}
            </MenuItem>
          ))}
        </TextField>
        <TextField
          select
          label="Division"
          value={selectedDivisionId}
          onChange={(event) => setSelectedDivisionId(event.target.value)}
          sx={{ minWidth: 280 }}
        >
          <MenuItem value="">All divisions</MenuItem>
          {divisionsInScope.map((item) => (
            <MenuItem key={item.id} value={item.id}>
              {item.name}
            </MenuItem>
          ))}
        </TextField>
        <TextField
          type="datetime-local"
          label="From"
          value={from}
          onChange={(event) => setFrom(event.target.value)}
          slotProps={{ inputLabel: { shrink: true } }}
        />
        <TextField
          type="datetime-local"
          label="To"
          value={to}
          onChange={(event) => setTo(event.target.value)}
          slotProps={{ inputLabel: { shrink: true } }}
        />
        <Button variant="contained" onClick={() => void loadOverview()} disabled={!selectedTournamentId || loading}>
          {loading ? "Loading..." : "Refresh"}
        </Button>
      </Stack>

      {overview ? (
        <>
          <Alert severity={overview.data_source === "neo4j" ? "success" : "info"}>
            Data source: {overview.data_source}
          </Alert>

          <Grid container spacing={2}>
            <Grid size={{ xs: 12, md: 4 }}>
              <SectionCard title="Total Events" titleVariant="overline">
                <Typography variant="h4">{overview.summary.kpis.total_events}</Typography>
              </SectionCard>
            </Grid>
            <Grid size={{ xs: 12, md: 4 }}>
              <SectionCard title="Transition Events" titleVariant="overline">
                <Typography variant="h4">{overview.summary.kpis.transition_events}</Typography>
              </SectionCard>
            </Grid>
            <Grid size={{ xs: 12, md: 4 }}>
              <SectionCard title="Score Events" titleVariant="overline">
                <Typography variant="h4">{overview.summary.kpis.score_events}</Typography>
              </SectionCard>
            </Grid>
          </Grid>

          <Grid container spacing={2}>
            <Grid size={{ xs: 12, md: 6 }}>
              <SectionCard title="Peak Hourly Volume" titleVariant="overline">
                <Typography variant="h5">{peakTrendBucket ? peakTrendBucket.total_events : 0}</Typography>
                <Typography variant="body2" color="text.secondary">
                  {peakTrendBucket
                    ? `Bucket starting ${new Date(peakTrendBucket.bucket_start).toLocaleString()}`
                    : "No throughput data for current scope"}
                </Typography>
              </SectionCard>
            </Grid>
            <Grid size={{ xs: 12, md: 6 }}>
              <SectionCard title="Active Roles" titleVariant="overline">
                <Typography variant="h5">{overview.insights.actor_role_activity.length}</Typography>
                <Typography variant="body2" color="text.secondary">
                  Distinct actor roles emitting events in this scope.
                </Typography>
              </SectionCard>
            </Grid>
          </Grid>

          <SectionCard title="Throughput Trend (Hourly)">
              {overview.insights.throughput_trend.length === 0 ? (
                <Alert severity="info">No throughput trend data available in this scope.</Alert>
              ) : (
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Bucket Start</TableCell>
                      <TableCell align="right">Total</TableCell>
                      <TableCell align="right">Transitions</TableCell>
                      <TableCell align="right">Scores</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {overview.insights.throughput_trend.map((item) => (
                      <TableRow key={item.bucket_start}>
                        <TableCell>{new Date(item.bucket_start).toLocaleString()}</TableCell>
                        <TableCell align="right">{item.total_events}</TableCell>
                        <TableCell align="right">{item.transition_events}</TableCell>
                        <TableCell align="right">{item.score_events}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
          </SectionCard>

          <SectionCard title="Top Active Matches">
              {overview.insights.top_active_matches.length === 0 ? (
                <Alert severity="info">No match activity found in this scope.</Alert>
              ) : (
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Match ID</TableCell>
                      <TableCell align="right">Event Count</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {overview.insights.top_active_matches.map((item) => (
                      <TableRow key={item.match_id}>
                        <TableCell>{item.match_id}</TableCell>
                        <TableCell align="right">{item.event_count}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
          </SectionCard>

          <SectionCard title="Actor Role Activity">
              {overview.insights.actor_role_activity.length === 0 ? (
                <Alert severity="info">No actor-role activity found in this scope.</Alert>
              ) : (
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Role</TableCell>
                      <TableCell align="right">Event Count</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {overview.insights.actor_role_activity.map((item) => (
                      <TableRow key={item.actor_role}>
                        <TableCell>{item.actor_role}</TableCell>
                        <TableCell align="right">{item.event_count}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
          </SectionCard>

          <SectionCard title="Match State Overview">
              {overview.state_overview.state_counts.length === 0 ? (
                <Alert severity="info">No state transitions in current scope.</Alert>
              ) : (
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>State</TableCell>
                      <TableCell align="right">Count</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {overview.state_overview.state_counts.map((item) => (
                      <TableRow key={item.state}>
                        <TableCell>{item.state}</TableCell>
                        <TableCell align="right">{item.count}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
          </SectionCard>

          <SectionCard title="Recent Events">
              {overview.recent_events.length === 0 ? (
                <Alert severity="info">No recent events in this filter range.</Alert>
              ) : (
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Occurred At</TableCell>
                      <TableCell>Type</TableCell>
                      <TableCell>Aggregate</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {overview.recent_events.map((event) => (
                      <TableRow key={event.event_id}>
                        <TableCell>{new Date(event.occurred_at).toLocaleString()}</TableCell>
                        <TableCell>{event.event_type}</TableCell>
                        <TableCell>{event.aggregate_id}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
          </SectionCard>
        </>
      ) : (
        <Alert severity="info">Select a tournament and load analytics overview.</Alert>
      )}
    </Stack>
  );
}
