import { Alert, Card, CardContent, Stack, Typography } from "@mui/material";
import type { Meta, StoryObj } from "@storybook/react";

import { analytics_overview_fixture } from "@zanshin/fixtures";

function AnalyticsOverviewCard() {
  return (
    <Stack spacing={2} sx={{ maxWidth: 720, p: 2 }}>
      <Typography variant="h4">Analytics Dashboard</Typography>
      <Alert severity={analytics_overview_fixture.data_source === "neo4j" ? "success" : "info"}>
        Data source: {analytics_overview_fixture.data_source}
      </Alert>
      <Card>
        <CardContent>
          <Typography variant="overline">Total Events</Typography>
          <Typography variant="h4">{analytics_overview_fixture.summary.kpis.total_events}</Typography>
        </CardContent>
      </Card>
    </Stack>
  );
}

const meta = {
  title: "analytics/dashboard_overview",
  component: AnalyticsOverviewCard
} satisfies Meta<typeof AnalyticsOverviewCard>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Default: Story = {};
