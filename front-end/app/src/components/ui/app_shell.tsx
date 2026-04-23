import {
  AppBar,
  Box,
  Button,
  Chip,
  Container,
  Stack,
  TextField,
  Toolbar,
  Typography
} from "@mui/material";
import { NavLink } from "@remix-run/react";
import { useState, type PropsWithChildren } from "react";

import { get_stored_token, set_stored_token } from "@zanshin/providers";

export function AppShell({ children }: PropsWithChildren) {
  const [token, set_token] = useState(() => get_stored_token() ?? "");

  function save_token() {
    set_stored_token(token);
  }

  function clear_token() {
    set_token("");
    set_stored_token("");
  }

  return (
    <Box sx={{ minHeight: "100vh", backgroundColor: "#eef2f7" }}>
      <AppBar position="sticky" elevation={0} color="primary">
        <Toolbar
          sx={{
            display: "flex",
            justifyContent: "space-between",
            gap: 2,
            flexWrap: "wrap",
            alignItems: "flex-start",
            py: 1.5
          }}
        >
          <Stack spacing={1.5}>
            <Typography variant="h6" sx={{ fontWeight: 700 }}>
              Zanshin
            </Typography>
            <Stack direction="row" spacing={1} sx={{ flexWrap: "wrap", alignItems: "center" }}>
              <Chip size="small" label="Consumer" color="secondary" />
              <Button component={NavLink} to="/" color="inherit" sx={{ textTransform: "none" }}>
                Dashboard
              </Button>
              <Button component={NavLink} to="/matches" color="inherit" sx={{ textTransform: "none" }}>
                Matches
              </Button>
              <Chip size="small" label="Admin" color="secondary" sx={{ ml: 1 }} />
              <Button component={NavLink} to="/admin" color="inherit" sx={{ textTransform: "none" }}>
                Console
              </Button>
              <Button component={NavLink} to="/admin/tournaments" color="inherit" sx={{ textTransform: "none" }}>
                Tournaments
              </Button>
              <Button component={NavLink} to="/admin/analytics" color="inherit" sx={{ textTransform: "none" }}>
                Analytics
              </Button>
              <Button component={NavLink} to="/admin/competitors" color="inherit" sx={{ textTransform: "none" }}>
                Competitors
              </Button>
              <Button
                component={NavLink}
                to="/admin/gradings/results"
                color="inherit"
                sx={{ textTransform: "none" }}
              >
                Grading Results
              </Button>
            </Stack>
          </Stack>
          <Stack spacing={0.75} sx={{ minWidth: { xs: "100%", lg: 460 }, maxWidth: 560 }}>
            <Typography variant="caption" sx={{ opacity: 0.9 }}>
              Admin auth token (stored only in this browser)
            </Typography>
            <Stack direction="row" spacing={1}>
              <TextField
                size="small"
                placeholder="Paste Bearer token"
                value={token}
                onChange={(event) => set_token(event.target.value)}
                fullWidth
                sx={{
                  bgcolor: "white",
                  borderRadius: 1,
                  "& .MuiInputBase-input": { py: 0.75 }
                }}
              />
              <Button variant="contained" color="secondary" onClick={save_token} sx={{ textTransform: "none" }}>
                Save
              </Button>
              <Button variant="outlined" color="inherit" onClick={clear_token} sx={{ textTransform: "none" }}>
                Clear
              </Button>
            </Stack>
            <Typography variant="caption" sx={{ opacity: 0.85 }}>
              Used for authenticated admin write requests.
            </Typography>
          </Stack>
        </Toolbar>
      </AppBar>
      <Container maxWidth="xl" sx={{ py: 3 }}>{children}</Container>
    </Box>
  );
}
