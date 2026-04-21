import { Alert, Button, Stack, TextField, Typography } from "@mui/material";
import { useState } from "react";

import { ApiError, fetchWithSchema } from "~/lib/api/client";
import { dataEnvelopeSchema, genericEntitySchema } from "~/lib/schemas/common";
import { gradingResultListResponseSchema, type GradingResult } from "~/lib/schemas/gradings";

const singleResultEnvelopeSchema = dataEnvelopeSchema(genericEntitySchema);

export default function GradingResultsRoute() {
  const [sessionId, setSessionId] = useState("");
  const [results, setResults] = useState<GradingResult[]>([]);
  const [selectedResultId, setSelectedResultId] = useState("");
  const [error, setError] = useState<string | null>(null);

  async function loadResults() {
    try {
      const response = await fetchWithSchema(
        `/api/v1/gradings/sessions/${sessionId}/results`,
        gradingResultListResponseSchema
      );
      setResults(response.data);
      setError(null);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_load_grading_results";
      setError(message);
    }
  }

  async function compute() {
    try {
      await fetchWithSchema(`/api/v1/gradings/results/${selectedResultId}/compute`, singleResultEnvelopeSchema, {
        method: "POST"
      });
      setError(null);
      if (sessionId) {
        await loadResults();
      }
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_compute_result";
      setError(message);
    }
  }

  async function finalizeResult() {
    try {
      await fetchWithSchema(
        `/api/v1/gradings/results/${selectedResultId}/finalize`,
        singleResultEnvelopeSchema,
        { method: "POST" }
      );
      setError(null);
      if (sessionId) {
        await loadResults();
      }
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
          label="Session ID"
          value={sessionId}
          onChange={(e) => setSessionId(e.target.value)}
          fullWidth
        />
        <Button variant="contained" onClick={loadResults} disabled={!sessionId}>
          Load
        </Button>
      </Stack>

      <Stack direction="row" spacing={1}>
        <TextField
          label="Result ID"
          value={selectedResultId}
          onChange={(e) => setSelectedResultId(e.target.value)}
          fullWidth
        />
        <Button variant="outlined" onClick={compute} disabled={!selectedResultId}>
          Compute
        </Button>
        <Button variant="contained" onClick={finalizeResult} disabled={!selectedResultId}>
          Finalize
        </Button>
      </Stack>

      <Stack spacing={1}>
        {results.map((item) => (
          <Alert key={item.id} severity={item.locked_at ? "success" : "info"}>
            {item.target_grade} - {item.final_result} ({item.id})
          </Alert>
        ))}
      </Stack>
    </Stack>
  );
}
