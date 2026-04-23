import { AppBar, Box, Button, Container, Stack, TextField, Toolbar, Typography } from "@mui/material";
import { NavLink } from "@remix-run/react";
import { useState, type PropsWithChildren } from "react";

import { getStoredToken, setStoredToken } from "~/lib/auth/tokenStore";

export function AppShell({ children }: PropsWithChildren) {
  const [token, setToken] = useState(() => getStoredToken() ?? "");

  function saveToken() {
    setStoredToken(token);
  }

  return (
    <Box sx={{ minHeight: "100vh", backgroundColor: "#f7f8fa" }}>
      <AppBar position="static" elevation={0} color="primary">
        <Toolbar sx={{ display: "flex", justifyContent: "space-between", gap: 2, flexWrap: "wrap" }}>
          <Typography variant="h6">Zanshin</Typography>
          <Stack direction="row" spacing={2} sx={{ flexWrap: "wrap", alignItems: "center" }}>
            <Stack direction="row" spacing={1} sx={{ flexWrap: "wrap", alignItems: "center" }}>
              <Typography variant="caption" sx={{ opacity: 0.9 }}>
                Consumer
              </Typography>
              <Button component={NavLink} to="/" color="inherit">
                Dashboard
              </Button>
              <Button component={NavLink} to="/matches" color="inherit">
                Matches
              </Button>
            </Stack>
            <Stack direction="row" spacing={1} sx={{ flexWrap: "wrap", alignItems: "center" }}>
              <Typography variant="caption" sx={{ opacity: 0.9 }}>
                Admin
              </Typography>
              <Button component={NavLink} to="/admin" color="inherit">
                Console
              </Button>
              <Button component={NavLink} to="/admin/tournaments" color="inherit">
                Tournaments
              </Button>
              <Button component={NavLink} to="/admin/analytics" color="inherit">
                Analytics
              </Button>
              <Button component={NavLink} to="/admin/competitors" color="inherit">
                Competitors
              </Button>
              <Button component={NavLink} to="/admin/gradings/results" color="inherit">
                Grading Results
              </Button>
            </Stack>
          </Stack>
          <Stack direction="row" spacing={1} sx={{ minWidth: 340 }}>
            <TextField
              size="small"
              placeholder="Admin bearer token"
              value={token}
              onChange={(e) => setToken(e.target.value)}
              fullWidth
              sx={{
                bgcolor: "white",
                borderRadius: 1,
                "& .MuiInputBase-input": { py: 0.75 }
              }}
            />
            <Button variant="contained" color="secondary" onClick={saveToken}>
              Save Admin Token
            </Button>
          </Stack>
        </Toolbar>
      </AppBar>
      <Container sx={{ py: 3 }}>{children}</Container>
    </Box>
  );
}
