import { Alert, Button, MenuItem, Stack, TextField } from "@mui/material";
import { useLoaderData } from "@remix-run/react";
import { useState } from "react";
import { z } from "zod";

import { ApiError, fetchWithSchema } from "@zanshin/api";
import { PageTitle } from "@zanshin/components";
import {
  CompetitorListResponseSchema,
  GradingResultListResponseSchema,
  GradingResultResponseSchema,
  GradingSessionListResponseSchema,
  TournamentListResponseSchema
} from "@zanshin/schemas";
import { type Competitor, type GradingResult, type GradingSession, type Tournament } from "@zanshin/types";

export async function clientLoader() {
  const [tournamentResponse, competitorResponse] = await Promise.all([
    fetchWithSchema("/api/v1/tournaments", TournamentListResponseSchema),
    fetchWithSchema("/api/v1/competitors", CompetitorListResponseSchema)
  ]);

  const initialTournaments = tournamentResponse.data;
  const initialCompetitors = competitorResponse.data;
  const initialSelectedTournamentId = initialTournaments[0]?.id ?? "";
  const initialSelectedCompetitorId = initialCompetitors[0]?.id ?? "";

  if (!initialSelectedTournamentId) {
    return {
      initialTournaments,
      initialSelectedTournamentId,
      initialSessions: [] as GradingSession[],
      initialSelectedSessionId: "",
      initialCompetitors,
      initialSelectedCompetitorId
    };
  }

  const sessionResponse = await fetchWithSchema(
    `/api/v1/gradings/sessions?tournament_id=${encodeURIComponent(initialSelectedTournamentId)}`,
    GradingSessionListResponseSchema
  );
  const initialSessions = sessionResponse.data;

  return {
    initialTournaments,
    initialSelectedTournamentId,
    initialSessions,
    initialSelectedSessionId: initialSessions[0]?.id ?? "",
    initialCompetitors,
    initialSelectedCompetitorId
  };
}

export default function GradingResultsRoute() {
  const {
    initialTournaments,
    initialSelectedTournamentId,
    initialSessions,
    initialSelectedSessionId,
    initialCompetitors,
    initialSelectedCompetitorId
  } = useLoaderData<typeof clientLoader>();

  const tournaments: Tournament[] = initialTournaments;
  const [selectedTournamentId, setSelectedTournamentId] = useState(initialSelectedTournamentId);
  const [sessions, setSessions] = useState<GradingSession[]>(initialSessions);
  const [selectedSessionId, setSelectedSessionId] = useState(initialSelectedSessionId);
  const competitors: Competitor[] = initialCompetitors;
  const [selectedCompetitorId, setSelectedCompetitorId] = useState(initialSelectedCompetitorId);
  const [targetGrade, setTargetGrade] = useState("4dan");
  const [results, setResults] = useState<GradingResult[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loadingResults, setLoadingResults] = useState(false);
  const [creatingResult, setCreatingResult] = useState(false);
  const [processingResultId, setProcessingResultId] = useState<string | null>(null);

  const CreateResultSchema = z.object({
    competitor_id: z.string().uuid("Please select a valid competitor"),
    target_grade: z
      .string()
      .trim()
      .min(2, "Target grade is required")
      .regex(/^\d+\s*(kyu|dan)$/i, "Use format like 2kyu or 4dan")
  });

  async function loadSessions(tournamentId: string) {
    try {
      const response = await fetchWithSchema(
        `/api/v1/gradings/sessions?tournament_id=${encodeURIComponent(tournamentId)}`,
        GradingSessionListResponseSchema
      );
      setSessions(response.data);
      setSelectedSessionId(response.data[0]?.id ?? "");
      setError(null);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_load_grading_sessions";
      setError(message);
    }
  }

  async function loadResults() {
    if (!selectedSessionId) return;
    setLoadingResults(true);
    try {
      const response = await fetchWithSchema(
        `/api/v1/gradings/sessions/${selectedSessionId}/results`,
        GradingResultListResponseSchema
      );
      setResults(response.data);
      setError(null);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_load_grading_results";
      setError(message);
    } finally {
      setLoadingResults(false);
    }
  }

  async function createResult() {
    if (!selectedSessionId || !selectedCompetitorId || !targetGrade.trim()) return;
    const parsed = CreateResultSchema.safeParse({
      competitor_id: selectedCompetitorId,
      target_grade: targetGrade
    });

    if (!parsed.success) {
      setError(parsed.error.issues[0]?.message ?? "invalid_grading_result_payload");
      return;
    }

    setCreatingResult(true);
    try {
      await fetchWithSchema(`/api/v1/gradings/sessions/${selectedSessionId}/results`, GradingResultResponseSchema, {
        method: "POST",
        body: parsed.data
      });
      await loadResults();
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_create_result";
      setError(message);
    } finally {
      setCreatingResult(false);
    }
  }

  async function compute(resultId: string) {
    setProcessingResultId(resultId);
    try {
      await fetchWithSchema(`/api/v1/gradings/results/${resultId}/compute`, GradingResultResponseSchema, {
        method: "POST"
      });
      setError(null);
      await loadResults();
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_compute_result";
      setError(message);
    } finally {
      setProcessingResultId(null);
    }
  }

  async function finalizeResult(resultId: string) {
    setProcessingResultId(resultId);
    try {
      await fetchWithSchema(`/api/v1/gradings/results/${resultId}/finalize`, GradingResultResponseSchema, {
        method: "POST"
      });
      setError(null);
      await loadResults();
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_finalize_result";
      setError(message);
    } finally {
      setProcessingResultId(null);
    }
  }

  async function selectTournament(tournamentId: string) {
    setSelectedTournamentId(tournamentId);
    setSelectedSessionId("");

    if (!tournamentId) {
      setSessions([]);
      setResults([]);
      return;
    }

    await loadSessions(tournamentId);
    setResults([]);
  }

  return (
    <Stack spacing={2}>
      <PageTitle title="Grading Results" />
      {error ? <Alert severity="error">{error}</Alert> : null}

      <Stack direction="row" spacing={1}>
        <TextField
          select
          label="Tournament"
          value={selectedTournamentId}
          onChange={(e) => void selectTournament(e.target.value)}
          sx={{ minWidth: 300 }}
        >
          {tournaments.map((item) => (
            <MenuItem key={item.id} value={item.id}>
              {item.name}
            </MenuItem>
          ))}
        </TextField>
        <TextField
          select
          label="Session"
          value={selectedSessionId}
          onChange={(e) => setSelectedSessionId(e.target.value)}
          sx={{ minWidth: 300 }}
        >
          {sessions.map((item) => (
            <MenuItem key={item.id} value={item.id}>
              {item.name}
            </MenuItem>
          ))}
        </TextField>
        <Button variant="contained" onClick={loadResults} disabled={!selectedSessionId}>
          Load Results
        </Button>
      </Stack>

      <Stack direction="row" spacing={1}>
        <TextField
          select
          label="Competitor"
          value={selectedCompetitorId}
          onChange={(e) => setSelectedCompetitorId(e.target.value)}
          sx={{ minWidth: 340 }}
        >
          {competitors.map((item) => (
            <MenuItem key={item.id} value={item.id}>
              {item.display_name}
            </MenuItem>
          ))}
        </TextField>
        <TextField label="Target Grade" value={targetGrade} onChange={(e) => setTargetGrade(e.target.value)} fullWidth />
        <Button
          variant="contained"
          onClick={createResult}
          disabled={creatingResult || !selectedSessionId || !selectedCompetitorId || !targetGrade.trim()}
        >
          {creatingResult ? "Creating..." : "Create Result"}
        </Button>
      </Stack>

      {loadingResults ? <Alert severity="info">Loading grading results...</Alert> : null}
      {!loadingResults && results.length === 0 ? (
        <Alert severity="warning">No grading results loaded yet for this session.</Alert>
      ) : null}

      <Stack spacing={1}>
        {results.map((item) => (
          <Alert
            key={item.id}
            severity={item.locked_at ? "success" : "info"}
            action={
              <Stack direction="row" spacing={1}>
                <Button
                  size="small"
                  variant="outlined"
                  onClick={() => compute(item.id)}
                  disabled={processingResultId === item.id}
                >
                  {processingResultId === item.id ? "..." : "Compute"}
                </Button>
                <Button
                  size="small"
                  variant="contained"
                  onClick={() => finalizeResult(item.id)}
                  disabled={processingResultId === item.id}
                >
                  {processingResultId === item.id ? "..." : "Finalize"}
                </Button>
              </Stack>
            }
          >
            {item.target_grade} - {item.final_result} ({item.id})
          </Alert>
        ))}
      </Stack>
    </Stack>
  );
}
