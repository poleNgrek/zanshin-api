import { AppBar, Box, Button, Container, Stack, Toolbar, Typography } from "@mui/material";
import { NavLink } from "@remix-run/react";
import type { PropsWithChildren } from "react";

export function AppShell({ children }: PropsWithChildren) {
  return (
    <Box sx={{ minHeight: "100vh", backgroundColor: "#f7f8fa" }}>
      <AppBar position="static" elevation={0} color="primary">
        <Toolbar sx={{ display: "flex", justifyContent: "space-between" }}>
          <Typography variant="h6">Zanshin Admin</Typography>
          <Stack direction="row" spacing={1}>
            <Button component={NavLink} to="/" color="inherit">
              Dashboard
            </Button>
            <Button component={NavLink} to="/tournaments" color="inherit">
              Tournaments
            </Button>
            <Button component={NavLink} to="/gradings/results" color="inherit">
              Grading Results
            </Button>
          </Stack>
        </Toolbar>
      </AppBar>
      <Container sx={{ py: 3 }}>{children}</Container>
    </Box>
  );
}
