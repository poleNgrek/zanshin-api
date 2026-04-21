import { Alert, Button, Stack, TextField, Typography } from "@mui/material";
import { useLoaderData } from "@remix-run/react";
import { useState } from "react";
import { z } from "zod";

import { ApiError, fetchWithSchema } from "~/lib/api/client";
import {
  competitorListResponseSchema,
  competitorResponseSchema,
  type Competitor
} from "~/lib/schemas/competitors";

const competitorCreateSchema = z.object({
  display_name: z.string().trim().min(2, "Display name must be at least 2 characters"),
  federation_id: z.string().trim().optional()
});

export async function clientLoader() {
  const response = await fetchWithSchema("/api/v1/competitors", competitorListResponseSchema);
  return { initialCompetitors: response.data };
}

export default function CompetitorsRoute() {
  const { initialCompetitors } = useLoaderData<typeof clientLoader>();
  const [items, setItems] = useState<Competitor[]>(initialCompetitors);
  const [displayName, setDisplayName] = useState("");
  const [federationId, setFederationId] = useState("");
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function loadCompetitors() {
    setLoading(true);
    try {
      const response = await fetchWithSchema("/api/v1/competitors", competitorListResponseSchema);
      setItems(response.data);
      setError(null);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_load_competitors";
      setError(message);
    } finally {
      setLoading(false);
    }
  }

  async function createCompetitor() {
    const parsed = competitorCreateSchema.safeParse({
      display_name: displayName,
      federation_id: federationId || undefined
    });

    if (!parsed.success) {
      setError(parsed.error.issues[0]?.message ?? "invalid_competitor_payload");
      return;
    }

    setSaving(true);
    try {
      await fetchWithSchema("/api/v1/competitors", competitorResponseSchema, {
        method: "POST",
        body: parsed.data
      });
      setDisplayName("");
      setFederationId("");
      await loadCompetitors();
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "failed_to_create_competitor";
      setError(message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <Stack spacing={2}>
      <Typography variant="h4">Competitors</Typography>
      {error ? <Alert severity="error">{error}</Alert> : null}

      <Stack direction="row" spacing={1}>
        <TextField
          label="Display name"
          value={displayName}
          onChange={(e) => setDisplayName(e.target.value)}
          fullWidth
        />
        <TextField
          label="Federation ID (optional)"
          value={federationId}
          onChange={(e) => setFederationId(e.target.value)}
          fullWidth
        />
        <Button variant="contained" onClick={createCompetitor} disabled={saving}>
          {saving ? "Saving..." : "Create"}
        </Button>
      </Stack>

      {loading ? <Alert severity="info">Loading competitors...</Alert> : null}
      {!loading && items.length === 0 ? (
        <Alert severity="warning">No competitors yet. Create one to start grading workflows.</Alert>
      ) : null}

      <Stack spacing={1}>
        {items.map((item) => (
          <Alert key={item.id} severity="info">
            {item.display_name}
            {item.federation_id ? ` [${item.federation_id}]` : ""}
            {" - "}
            {item.id}
          </Alert>
        ))}
      </Stack>
    </Stack>
  );
}
