import { Alert, Stack } from "@mui/material";

import { PageTitle } from "@zanshin/components";

export default function AdminIndexRoute() {
  return (
    <Stack spacing={2}>
      <PageTitle title="Admin Console" />
      <Alert severity="info">
        Use the admin navigation links for tournament setup, analytics monitoring, competitor management, and grading
        operations.
      </Alert>
    </Stack>
  );
}
