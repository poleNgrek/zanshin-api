import { Card, CardContent, Grid, Typography } from "@mui/material";

export default function IndexRoute() {
  return (
    <Grid container spacing={2}>
      <Grid item xs={12}>
        <Typography variant="h4" component="h1" gutterBottom>
          Tournament Operations Dashboard
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Phase 3 foundation is active. Use the navigation bar to access tournaments and grading flows.
        </Typography>
      </Grid>
      <Grid item xs={12} md={4}>
        <Card>
          <CardContent>
            <Typography variant="h6">API Base</Typography>
            <Typography variant="body2">Configured via `API_BASE_URL` (default `http://localhost:4000`).</Typography>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={12} md={4}>
        <Card>
          <CardContent>
            <Typography variant="h6">Validation Layer</Typography>
            <Typography variant="body2">All API responses are parsed through Zod before UI usage.</Typography>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={12} md={4}>
        <Card>
          <CardContent>
            <Typography variant="h6">Testing</Typography>
            <Typography variant="body2">Use `bun test` for unit checks and Playwright for smoke E2E.</Typography>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  );
}
