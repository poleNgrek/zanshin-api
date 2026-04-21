import { Alert, Button, MenuItem, Stack, TextField, Typography } from "@mui/material";
import { useEffect, useState } from "react";

import { ApiError, fetchWithSchema } from "~/lib/api/client";
import {
  divisionListResponseSchema,
  divisionResponseSchema,
  type Division
} from "~/lib/schemas/divisions";
import {
  gradingSessionListResponseSchema,
  gradingSessionResponseSchema,
  type GradingSession
} from "~/lib/schemas/gradingSessions";
import {
  tournamentListResponseSchema,
  tournamentResponseSchema,
  type Tournament
} from "~/lib/schemas/tournaments";

export default function TournamentsRoute() {
  const [items, setItems] = useState<Tournament[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [name, setName] = useState("");
  const [startsOn, setStartsOn] = useState("");
  const [selectedTournamentId, setSelectedTournamentId] = useState("");
  const [divisions, setDivisions] = useState<Division[]>([]);
  const [divisionName, setDivisionName] = useState("");
  const [divisionFormat, setDivisionFormat] = useState("bracket");
  const [sessions, setSessions] = useState<GradingSession[]>([]);
  const [sessionName, setSessionName] = useState("");

  async function loadTournaments() {
    try {
      const response = await fetchWithSchema("/api/v1/tournaments", tournamentListResponseSchema);
      setItems(response.data);
      if (response.data.length > 0 && !selectedTournamentId) {
        setSelectedTournamentId(response.data[0].id);
      }
      setError(null);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_load_tournaments";
      setError(message);
    }
  }

  useEffect(() => {
    void loadTournaments();
  }, []);

  useEffect(() => {
    if (!selectedTournamentId) return;
    void loadDivisions(selectedTournamentId);
    void loadSessions(selectedTournamentId);
  }, [selectedTournamentId]);

  async function createTournament() {
    try {
      await fetchWithSchema("/api/v1/tournaments", tournamentResponseSchema, {
        method: "POST",
        body: {
          name,
          starts_on: startsOn || undefined
        }
      });
      setName("");
      setStartsOn("");
      await loadTournaments();
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_create_tournament";
      setError(message);
    }
  }

  async function loadDivisions(tournamentId: string) {
    try {
      const response = await fetchWithSchema(
        `/api/v1/divisions?tournament_id=${encodeURIComponent(tournamentId)}`,
        divisionListResponseSchema
      );
      setDivisions(response.data);
      setError(null);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_load_divisions";
      setError(message);
    }
  }

  async function createDivision() {
    if (!selectedTournamentId) return;
    try {
      await fetchWithSchema("/api/v1/divisions", divisionResponseSchema, {
        method: "POST",
        body: {
          tournament_id: selectedTournamentId,
          name: divisionName,
          format: divisionFormat
        }
      });
      setDivisionName("");
      await loadDivisions(selectedTournamentId);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_create_division";
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
      setError(null);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_load_grading_sessions";
      setError(message);
    }
  }

  async function createSession() {
    if (!selectedTournamentId) return;
    try {
      await fetchWithSchema("/api/v1/gradings/sessions", gradingSessionResponseSchema, {
        method: "POST",
        body: {
          tournament_id: selectedTournamentId,
          name: sessionName
        }
      });
      setSessionName("");
      await loadSessions(selectedTournamentId);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_create_grading_session";
      setError(message);
    }
  }

  return (
    <Stack spacing={2}>
      <Typography variant="h4">Tournaments</Typography>
      {error ? <Alert severity="error">{error}</Alert> : null}

      <Stack direction="row" spacing={1}>
        <TextField
          label="Tournament name"
          value={name}
          onChange={(e) => setName(e.target.value)}
          fullWidth
        />
        <TextField
          type="date"
          value={startsOn}
          onChange={(e) => setStartsOn(e.target.value)}
          InputLabelProps={{ shrink: true }}
        />
        <Button variant="contained" onClick={createTournament} disabled={!name.trim()}>
          Create
        </Button>
      </Stack>

      <Stack spacing={1}>
        {items.map((item) => (
          <Alert key={item.id} severity="info">
            {item.name} ({item.id})
          </Alert>
        ))}
      </Stack>

      <Typography variant="h5" sx={{ pt: 2 }}>
        Division Setup
      </Typography>
      <Stack direction="row" spacing={1} sx={{ flexWrap: "wrap" }}>
        <TextField
          select
          label="Tournament"
          value={selectedTournamentId}
          onChange={(e) => setSelectedTournamentId(e.target.value)}
          sx={{ minWidth: 280 }}
        >
          {items.map((item) => (
            <MenuItem key={item.id} value={item.id}>
              {item.name}
            </MenuItem>
          ))}
        </TextField>
        <TextField
          label="Division name"
          value={divisionName}
          onChange={(e) => setDivisionName(e.target.value)}
          fullWidth
        />
        <TextField select label="Format" value={divisionFormat} onChange={(e) => setDivisionFormat(e.target.value)}>
          <MenuItem value="bracket">bracket</MenuItem>
          <MenuItem value="swiss">swiss</MenuItem>
          <MenuItem value="round_robin">round_robin</MenuItem>
          <MenuItem value="team">team</MenuItem>
          <MenuItem value="hybrid">hybrid</MenuItem>
        </TextField>
        <Button
          variant="contained"
          onClick={createDivision}
          disabled={!selectedTournamentId || !divisionName.trim()}
        >
          Create Division
        </Button>
      </Stack>

      <Stack spacing={1}>
        {divisions.map((division) => (
          <Alert key={division.id} severity="success">
            {division.name} [{division.format}] ({division.id})
          </Alert>
        ))}
      </Stack>

      <Typography variant="h5" sx={{ pt: 2 }}>
        Grading Session Setup
      </Typography>
      <Stack direction="row" spacing={1}>
        <TextField
          label="Session name"
          value={sessionName}
          onChange={(e) => setSessionName(e.target.value)}
          fullWidth
        />
        <Button variant="contained" onClick={createSession} disabled={!selectedTournamentId || !sessionName.trim()}>
          Create Session
        </Button>
      </Stack>

      <Stack spacing={1}>
        {sessions.map((session) => (
          <Alert key={session.id} severity="warning">
            {session.name} ({session.id})
          </Alert>
        ))}
      </Stack>
    </Stack>
  );
}
