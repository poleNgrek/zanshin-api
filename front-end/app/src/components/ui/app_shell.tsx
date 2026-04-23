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
  const navButtonSx = {
    textTransform: "none",
    borderRadius: 1.5,
    px: 1.25,
    minHeight: 32,
    fontSize: 13,
    "&[aria-current='page']": {
      backgroundColor: "rgba(255,255,255,0.18)"
    }
  };

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
            <Stack direction="row" spacing={0.75} sx={{ flexWrap: "wrap", alignItems: "center" }}>
              <Chip size="small" label="Consumer" color="secondary" />
              <Button component={NavLink} to="/" color="inherit" sx={navButtonSx}>
                Dashboard
              </Button>
              <Button component={NavLink} to="/matches" color="inherit" sx={navButtonSx}>
                Matches
              </Button>
              <Chip size="small" label="Admin" color="secondary" sx={{ ml: 1 }} />
              <Button component={NavLink} to="/admin" color="inherit" sx={navButtonSx}>
                Console
              </Button>
              <Button component={NavLink} to="/admin/tournaments" color="inherit" sx={navButtonSx}>
                Tournaments
              </Button>
              <Button component={NavLink} to="/admin/analytics" color="inherit" sx={navButtonSx}>
                Analytics
              </Button>
              <Button component={NavLink} to="/admin/competitors" color="inherit" sx={navButtonSx}>
                Competitors
              </Button>
              <Button component={NavLink} to="/admin/gradings/results" color="inherit" sx={navButtonSx}>
                Grading Results
              </Button>
            </Stack>
          </Stack>
          <Stack spacing={0.75} sx={{ minWidth: { xs: "100%", lg: 460 }, maxWidth: 560 }}>
            <Typography variant="caption" sx={{ opacity: 0.9 }}>
              Admin auth token (stored only in this browser)
            </Typography>
            <Stack direction={{ xs: "column", md: "row" }} spacing={1}>
              <TextField
                size="small"
                placeholder="Paste Bearer token"
                value={token}
                onChange={(event) => set_token(event.target.value)}
                fullWidth
                sx={{
                  bgcolor: "white",
                  borderRadius: 1,
                  minWidth: { md: 320 },
                  "& .MuiInputBase-input": { py: 0.75 }
                }}
              />
              <Button
                variant="contained"
                color="secondary"
                onClick={save_token}
                sx={{ textTransform: "none", minWidth: 84 }}
              >
                Save
              </Button>
              <Button
                variant="outlined"
                color="inherit"
                onClick={clear_token}
                sx={{ textTransform: "none", minWidth: 84 }}
              >
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
