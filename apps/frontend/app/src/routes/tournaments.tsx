import { Alert, Button, MenuItem, Stack, TextField, Typography } from "@mui/material";
import { useLoaderData } from "@remix-run/react";
import { useState } from "react";
import { z } from "zod";

import { ApiError, fetchWithSchema } from "@zanshin/api";
import { InfoAlertList, PageTitle } from "@zanshin/components";
import {
  DivisionListResponseSchema,
  DivisionResponseSchema,
  GradingSessionListResponseSchema,
  GradingSessionResponseSchema,
  TournamentListResponseSchema,
  TournamentResponseSchema
} from "@zanshin/schemas";
import { type Division, type GradingSession, type Tournament } from "@zanshin/types";

export async function clientLoader() {
  const tournamentResponse = await fetchWithSchema("/api/v1/tournaments", TournamentListResponseSchema);
  const initialTournaments = tournamentResponse.data;
  const initialSelectedTournamentId = initialTournaments[0]?.id ?? "";

  if (!initialSelectedTournamentId) {
    return {
      initialTournaments,
      initialSelectedTournamentId,
      initialDivisions: [] as Division[],
      initialSessions: [] as GradingSession[]
    };
  }

  const [divisionResponse, sessionResponse] = await Promise.all([
    fetchWithSchema(
      `/api/v1/divisions?tournament_id=${encodeURIComponent(initialSelectedTournamentId)}`,
      DivisionListResponseSchema
    ),
    fetchWithSchema(
      `/api/v1/gradings/sessions?tournament_id=${encodeURIComponent(initialSelectedTournamentId)}`,
      GradingSessionListResponseSchema
    )
  ]);

  return {
    initialTournaments,
    initialSelectedTournamentId,
    initialDivisions: divisionResponse.data,
    initialSessions: sessionResponse.data
  };
}

export default function TournamentsRoute() {
  const { initialTournaments, initialSelectedTournamentId, initialDivisions, initialSessions } =
    useLoaderData<typeof clientLoader>();

  const [items, setItems] = useState<Tournament[]>(initialTournaments);
  const [error, setError] = useState<string | null>(null);
  const [name, setName] = useState("");
  const [startsOn, setStartsOn] = useState("");
  const [selectedTournamentId, setSelectedTournamentId] = useState(initialSelectedTournamentId);
  const [divisions, setDivisions] = useState<Division[]>(initialDivisions);
  const [divisionName, setDivisionName] = useState("");
  const [divisionFormat, setDivisionFormat] = useState("bracket");
  const [sessions, setSessions] = useState<GradingSession[]>(initialSessions);
  const [sessionName, setSessionName] = useState("");
  const [loadingTournaments, setLoadingTournaments] = useState(false);
  const [creatingTournament, setCreatingTournament] = useState(false);
  const [creatingDivision, setCreatingDivision] = useState(false);
  const [creatingSession, setCreatingSession] = useState(false);

  const CreateTournamentSchema = z.object({
    name: z.string().trim().min(3, "Tournament name must be at least 3 characters"),
    starts_on: z.string().optional()
  });

  const CreateDivisionSchema = z.object({
    name: z.string().trim().min(2, "Division name must be at least 2 characters"),
    format: z.enum(["bracket", "swiss", "round_robin", "team", "hybrid"])
  });

  const CreateSessionSchema = z.object({
    name: z.string().trim().min(2, "Session name must be at least 2 characters")
  });

  async function loadTournaments() {
    setLoadingTournaments(true);
    try {
      const response = await fetchWithSchema("/api/v1/tournaments", TournamentListResponseSchema);
      setItems(response.data);

      const currentTournamentExists = response.data.some((item) => item.id === selectedTournamentId);
      const nextSelectedTournamentId = currentTournamentExists ? selectedTournamentId : (response.data[0]?.id ?? "");

      setSelectedTournamentId(nextSelectedTournamentId);

      if (!nextSelectedTournamentId) {
        setDivisions([]);
        setSessions([]);
      } else {
        await Promise.all([loadDivisions(nextSelectedTournamentId), loadSessions(nextSelectedTournamentId)]);
      }
      setError(null);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_load_tournaments";
      setError(message);
    } finally {
      setLoadingTournaments(false);
    }
  }

  async function createTournament() {
    const parsed = CreateTournamentSchema.safeParse({
      name,
      starts_on: startsOn || undefined
    });

    if (!parsed.success) {
      setError(parsed.error.issues[0]?.message ?? "invalid_tournament_payload");
      return;
    }

    setCreatingTournament(true);
    try {
      await fetchWithSchema("/api/v1/tournaments", TournamentResponseSchema, {
        method: "POST",
        body: parsed.data
      });
      setName("");
      setStartsOn("");
      await loadTournaments();
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_create_tournament";
      setError(message);
    } finally {
      setCreatingTournament(false);
    }
  }

  async function loadDivisions(tournamentId: string) {
    try {
      const response = await fetchWithSchema(
        `/api/v1/divisions?tournament_id=${encodeURIComponent(tournamentId)}`,
        DivisionListResponseSchema
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
    const parsed = CreateDivisionSchema.safeParse({
      name: divisionName,
      format: divisionFormat
    });

    if (!parsed.success) {
      setError(parsed.error.issues[0]?.message ?? "invalid_division_payload");
      return;
    }

    setCreatingDivision(true);
    try {
      await fetchWithSchema("/api/v1/divisions", DivisionResponseSchema, {
        method: "POST",
        body: {
          tournament_id: selectedTournamentId,
          ...parsed.data
        }
      });
      setDivisionName("");
      await loadDivisions(selectedTournamentId);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_create_division";
      setError(message);
    } finally {
      setCreatingDivision(false);
    }
  }

  async function loadSessions(tournamentId: string) {
    try {
      const response = await fetchWithSchema(
        `/api/v1/gradings/sessions?tournament_id=${encodeURIComponent(tournamentId)}`,
        GradingSessionListResponseSchema
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
    const parsed = CreateSessionSchema.safeParse({ name: sessionName });

    if (!parsed.success) {
      setError(parsed.error.issues[0]?.message ?? "invalid_grading_session_payload");
      return;
    }

    setCreatingSession(true);
    try {
      await fetchWithSchema("/api/v1/gradings/sessions", GradingSessionResponseSchema, {
        method: "POST",
        body: {
          tournament_id: selectedTournamentId,
          name: parsed.data.name
        }
      });
      setSessionName("");
      await loadSessions(selectedTournamentId);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_create_grading_session";
      setError(message);
    } finally {
      setCreatingSession(false);
    }
  }

  async function selectTournament(tournamentId: string) {
    setSelectedTournamentId(tournamentId);
    if (!tournamentId) {
      setDivisions([]);
      setSessions([]);
      return;
    }

    await Promise.all([loadDivisions(tournamentId), loadSessions(tournamentId)]);
  }

  return (
    <Stack spacing={2}>
      <PageTitle title="Tournaments" />
      {error ? <Alert severity="error">{error}</Alert> : null}

      <Stack direction="row" spacing={1}>
        <TextField label="Tournament name" value={name} onChange={(e) => setName(e.target.value)} fullWidth />
        <TextField
          type="date"
          value={startsOn}
          onChange={(e) => setStartsOn(e.target.value)}
          slotProps={{ inputLabel: { shrink: true } }}
        />
        <Button variant="contained" onClick={createTournament} disabled={creatingTournament}>
          {creatingTournament ? "Creating..." : "Create"}
        </Button>
      </Stack>

      {loadingTournaments ? <Alert severity="info">Loading tournaments...</Alert> : null}
      {!loadingTournaments && items.length === 0 ? (
        <Alert severity="warning">No tournaments yet. Create your first tournament to continue.</Alert>
      ) : null}

      <InfoAlertList items={items.map((item) => ({ id: item.id, text: `${item.name} (${item.id})` }))} />

      <Typography variant="h5" sx={{ pt: 2 }}>
        Division Setup
      </Typography>
      <Stack direction="row" spacing={1} sx={{ flexWrap: "wrap" }}>
        <TextField
          select
          label="Tournament"
          value={selectedTournamentId}
          onChange={(e) => void selectTournament(e.target.value)}
          sx={{ minWidth: 280 }}
        >
          {items.map((item) => (
            <MenuItem key={item.id} value={item.id}>
              {item.name}
            </MenuItem>
          ))}
        </TextField>
        <TextField label="Division name" value={divisionName} onChange={(e) => setDivisionName(e.target.value)} fullWidth />
        <TextField select label="Format" value={divisionFormat} onChange={(e) => setDivisionFormat(e.target.value)}>
          <MenuItem value="bracket">bracket</MenuItem>
          <MenuItem value="swiss">swiss</MenuItem>
          <MenuItem value="round_robin">round_robin</MenuItem>
          <MenuItem value="team">team</MenuItem>
          <MenuItem value="hybrid">hybrid</MenuItem>
        </TextField>
        <Button variant="contained" onClick={createDivision} disabled={creatingDivision || !selectedTournamentId}>
          {creatingDivision ? "Creating..." : "Create Division"}
        </Button>
      </Stack>

      <InfoAlertList
        items={divisions.map((division) => ({
          id: division.id,
          severity: "success",
          text: `${division.name} [${division.format}] (${division.id})`
        }))}
      />

      <Typography variant="h5" sx={{ pt: 2 }}>
        Grading Session Setup
      </Typography>
      <Stack direction="row" spacing={1}>
        <TextField label="Session name" value={sessionName} onChange={(e) => setSessionName(e.target.value)} fullWidth />
        <Button variant="contained" onClick={createSession} disabled={creatingSession || !selectedTournamentId}>
          {creatingSession ? "Creating..." : "Create Session"}
        </Button>
      </Stack>

      <InfoAlertList
        items={sessions.map((session) => ({
          id: session.id,
          severity: "warning",
          text: `${session.name} (${session.id})`
        }))}
      />
    </Stack>
  );
}
