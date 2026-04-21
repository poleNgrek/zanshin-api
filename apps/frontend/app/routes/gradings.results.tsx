import { Alert, Button, MenuItem, Stack, TextField, Typography } from "@mui/material";
import { useEffect, useState } from "react";

import { ApiError, fetchWithSchema } from "~/lib/api/client";
import {
  competitorListResponseSchema,
  type Competitor
} from "~/lib/schemas/competitors";
import {
  gradingResultListResponseSchema,
  gradingResultResponseSchema,
  type GradingResult
} from "~/lib/schemas/gradings";
import {
  gradingSessionListResponseSchema,
  type GradingSession
} from "~/lib/schemas/gradingSessions";
import { tournamentListResponseSchema, type Tournament } from "~/lib/schemas/tournaments";

export default function GradingResultsRoute() {
  const [tournaments, setTournaments] = useState<Tournament[]>([]);
  const [selectedTournamentId, setSelectedTournamentId] = useState("");
  const [sessions, setSessions] = useState<GradingSession[]>([]);
  const [selectedSessionId, setSelectedSessionId] = useState("");
  const [competitors, setCompetitors] = useState<Competitor[]>([]);
  const [selectedCompetitorId, setSelectedCompetitorId] = useState("");
  const [targetGrade, setTargetGrade] = useState("4dan");
  const [results, setResults] = useState<GradingResult[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    void loadTournaments();
    void loadCompetitors();
  }, []);

  useEffect(() => {
    if (!selectedTournamentId) return;
    void loadSessions(selectedTournamentId);
  }, [selectedTournamentId]);

  async function loadTournaments() {
    try {
      const response = await fetchWithSchema("/api/v1/tournaments", tournamentListResponseSchema);
      setTournaments(response.data);
      if (!selectedTournamentId && response.data.length > 0) {
        setSelectedTournamentId(response.data[0].id);
      }
      setError(null);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_load_tournaments";
      setError(message);
    }
  }

  async function loadSessions(tournamentId: string) {
    try {
      const response = await fetchWithSchema(
        `/api/v1/gradings/sessions?tournament_id=${encodeURIComponent(tournamentId)}`,
        gradingSessionListResponseSchema
      );
      setSessions(response.data);
      if (!selectedSessionId && response.data.length > 0) {
        setSelectedSessionId(response.data[0].id);
      }
      setError(null);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_load_grading_sessions";
      setError(message);
    }
  }

  async function loadCompetitors() {
    try {
      const response = await fetchWithSchema("/api/v1/competitors", competitorListResponseSchema);
      setCompetitors(response.data);
      if (!selectedCompetitorId && response.data.length > 0) {
        setSelectedCompetitorId(response.data[0].id);
      }
      setError(null);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_load_competitors";
      setError(message);
    }
  }

  async function loadResults() {
    if (!selectedSessionId) return;
    try {
      const response = await fetchWithSchema(
        `/api/v1/gradings/sessions/${selectedSessionId}/results`,
        gradingResultListResponseSchema
      );
      setResults(response.data);
      setError(null);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_load_grading_results";
      setError(message);
    }
  }

  async function createResult() {
    if (!selectedSessionId || !selectedCompetitorId || !targetGrade.trim()) return;
    try {
      await fetchWithSchema(
        `/api/v1/gradings/sessions/${selectedSessionId}/results`,
        gradingResultResponseSchema,
        {
          method: "POST",
          body: {
            competitor_id: selectedCompetitorId,
            target_grade: targetGrade
          }
        }
      );
      await loadResults();
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_create_result";
      setError(message);
    }
  }

  async function compute(resultId: string) {
    try {
      await fetchWithSchema(`/api/v1/gradings/results/${resultId}/compute`, gradingResultResponseSchema, {
        method: "POST"
      });
      setError(null);
      await loadResults();
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_compute_result";
      setError(message);
    }
  }

  async function finalizeResult(resultId: string) {
    try {
      await fetchWithSchema(`/api/v1/gradings/results/${resultId}/finalize`, gradingResultResponseSchema, {
        method: "POST"
      });
      setError(null);
      await loadResults();
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_finalize_result";
      setError(message);
    }
  }

  return (
    <Stack spacing={2}>
      <Typography variant="h4">Grading Results</Typography>
      {error ? <Alert severity="error">{error}</Alert> : null}

      <Stack direction="row" spacing={1}>
        <TextField
          select
          label="Tournament"
          value={selectedTournamentId}
          onChange={(e) => setSelectedTournamentId(e.target.value)}
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
        <TextField
          label="Target Grade"
          value={targetGrade}
          onChange={(e) => setTargetGrade(e.target.value)}
          fullWidth
        />
        <Button
          variant="contained"
          onClick={createResult}
          disabled={!selectedSessionId || !selectedCompetitorId || !targetGrade.trim()}
        >
          Create Result
        </Button>
      </Stack>

      <Stack spacing={1}>
        {results.map((item) => (
          <Alert
            key={item.id}
            severity={item.locked_at ? "success" : "info"}
            action={
              <Stack direction="row" spacing={1}>
                <Button size="small" variant="outlined" onClick={() => compute(item.id)}>
                  Compute
                </Button>
                <Button size="small" variant="contained" onClick={() => finalizeResult(item.id)}>
                  Finalize
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
