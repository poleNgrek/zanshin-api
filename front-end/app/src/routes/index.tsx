import { Box, Chip, Grid, Stack, Typography } from "@mui/material";

import { SectionCard } from "@zanshin/components";

export default function IndexRoute() {
  return (
    <Stack spacing={2}>
      <Box
        sx={{
          borderRadius: 2,
          p: { xs: 2, md: 3 },
          background:
            "linear-gradient(135deg, rgba(31,75,153,0.10) 0%, rgba(194,139,30,0.10) 100%)",
          border: "1px solid",
          borderColor: "divider"
        }}
      >
        <Stack direction="row" spacing={1} sx={{ mb: 1, flexWrap: "wrap" }}>
          <Chip size="small" label="Consumer ready" color="primary" />
          <Chip size="small" label="Admin ready" color="secondary" />
        </Stack>
        <Typography variant="h4" component="h1" gutterBottom>
          Tournament Dashboard
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Use Consumer navigation for read-only match views and Admin navigation for management workflows.
        </Typography>
      </Box>
      <Grid container spacing={2}>
        <Grid size={{ xs: 12, md: 4 }}>
          <SectionCard title="API Base" sx={{ height: "100%" }}>
            <Typography variant="body2">
              Configured via `API_BASE_URL` (default `http://localhost:4000`).
            </Typography>
          </SectionCard>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <SectionCard title="Validation Layer" sx={{ height: "100%" }}>
            <Typography variant="body2">All API responses are parsed through Zod before UI usage.</Typography>
          </SectionCard>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <SectionCard title="Testing" sx={{ height: "100%" }}>
            <Typography variant="body2">Use `bun test` for unit checks and Playwright for smoke E2E.</Typography>
          </SectionCard>
        </Grid>
      </Grid>
      <SectionCard title="Quick Start">
        <Typography variant="body2" color="text.secondary">
          Set API token in header for admin writes, then open `Tournaments` to create data and `Matches` /
          `Analytics` to validate live updates.
        </Typography>
      </SectionCard>
    </Stack>
  );
}
