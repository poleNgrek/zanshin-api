import { Alert, Button, Stack, TextField, Typography } from "@mui/material";
import { useEffect, useState } from "react";

import { ApiError, fetchWithSchema } from "~/lib/api/client";
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

  async function loadTournaments() {
    try {
      const response = await fetchWithSchema("/api/v1/tournaments", tournamentListResponseSchema);
      setItems(response.data);
      setError(null);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_load_tournaments";
      setError(message);
    }
  }

  useEffect(() => {
    void loadTournaments();
  }, []);

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
    </Stack>
  );
}
