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
          <Typography variant="h6">Zanshin Admin</Typography>
          <Stack direction="row" spacing={1} sx={{ flexWrap: "wrap" }}>
            <Button component={NavLink} to="/" color="inherit">
              Dashboard
            </Button>
            <Button component={NavLink} to="/tournaments" color="inherit">
              Tournaments
            </Button>
            <Button component={NavLink} to="/competitors" color="inherit">
              Competitors
            </Button>
            <Button component={NavLink} to="/gradings/results" color="inherit">
              Grading Results
            </Button>
          </Stack>
          <Stack direction="row" spacing={1} sx={{ minWidth: 340 }}>
            <TextField
              size="small"
              placeholder="Bearer token"
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
              Save Token
            </Button>
          </Stack>
        </Toolbar>
      </AppBar>
      <Container sx={{ py: 3 }}>{children}</Container>
    </Box>
  );
}
