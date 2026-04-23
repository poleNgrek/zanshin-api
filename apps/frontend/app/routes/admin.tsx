import { Alert, Stack, Typography } from "@mui/material";

export default function AdminRoute() {
  return (
    <Stack spacing={2}>
      <Typography variant="h4">Admin Console</Typography>
      <Alert severity="info">
        Use the admin navigation links for tournament setup, competitor management, and grading operations.
      </Alert>
    </Stack>
  );
}
