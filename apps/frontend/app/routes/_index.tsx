import { Box, Card, CardContent, Stack, Typography } from "@mui/material";

export default function IndexRoute() {
  return (
    <Stack spacing={2}>
      <Box>
        <Typography variant="h4" component="h1" gutterBottom>
          Tournament Dashboard
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Use Consumer navigation for read-only match views and Admin navigation for management workflows.
        </Typography>
      </Box>
      <Stack direction={{ xs: "column", md: "row" }} spacing={2}>
        <Card sx={{ flex: 1 }}>
          <CardContent>
            <Typography variant="h6">API Base</Typography>
            <Typography variant="body2">Configured via `API_BASE_URL` (default `http://localhost:4000`).</Typography>
          </CardContent>
        </Card>
        <Card sx={{ flex: 1 }}>
          <CardContent>
            <Typography variant="h6">Validation Layer</Typography>
            <Typography variant="body2">All API responses are parsed through Zod before UI usage.</Typography>
          </CardContent>
        </Card>
        <Card sx={{ flex: 1 }}>
          <CardContent>
            <Typography variant="h6">Testing</Typography>
            <Typography variant="body2">Use `bun test` for unit checks and Playwright for smoke E2E.</Typography>
          </CardContent>
        </Card>
      </Stack>
    </Stack>
  );
}
