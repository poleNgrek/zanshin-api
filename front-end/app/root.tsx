import CssBaseline from "@mui/material/CssBaseline";
import { ThemeProvider, createTheme } from "@mui/material/styles";
import type { LinksFunction } from "@remix-run/node";
import { Alert, Box, Button, Stack, Typography } from "@mui/material";
import {
  isRouteErrorResponse,
  Links,
  LiveReload,
  Meta,
  Outlet,
  Scripts,
  ScrollRestoration,
  useRouteError
} from "@remix-run/react";

import { AppShell } from "@zanshin/components";
import stylesheet from "~/styles.css";

export const links: LinksFunction = () => [
  { rel: "stylesheet", href: stylesheet },
  { rel: "icon", href: "/favicon.svg", type: "image/svg+xml" }
];

const theme = createTheme({
  palette: {
    mode: "light",
    primary: { main: "#1f4b99" },
    secondary: { main: "#c28b1e" },
    background: {
      default: "#eef2f7",
      paper: "#ffffff"
    }
  },
  shape: {
    borderRadius: 10
  },
  typography: {
    h3: { fontSize: "2rem", fontWeight: 700 },
    h4: { fontSize: "1.65rem", fontWeight: 700 },
    h5: { fontSize: "1.25rem", fontWeight: 700 }
  }
});

export default function App() {
  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width,initial-scale=1" />
        <Meta />
        <Links />
      </head>
      <body>
        <ThemeProvider theme={theme}>
          <CssBaseline />
          <AppShell>
            <Outlet />
          </AppShell>
        </ThemeProvider>
        <ScrollRestoration />
        <Scripts />
        <LiveReload />
      </body>
    </html>
  );
}

export function ErrorBoundary() {
  const error = useRouteError();

  const message = isRouteErrorResponse(error)
    ? `${error.status} ${error.statusText}`
    : error instanceof Error
      ? error.message
      : "Unknown application error";

  const isApiIssue = message.includes("Failed to fetch") || message.includes("api_unreachable");

  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width,initial-scale=1" />
        <Meta />
        <Links />
      </head>
      <body>
        <ThemeProvider theme={theme}>
          <CssBaseline />
          <Box sx={{ minHeight: "100vh", display: "grid", placeItems: "center", p: 2, bgcolor: "#eef2f7" }}>
            <Stack spacing={2} sx={{ width: "100%", maxWidth: 680 }}>
              <Typography variant="h4">Something went wrong</Typography>
              <Alert severity={isApiIssue ? "warning" : "error"}>
                {isApiIssue
                  ? "The frontend could not reach the API. Check API server status and API_BASE_URL."
                  : message}
              </Alert>
              <Stack direction="row" spacing={1}>
                <Button variant="contained" href="/">
                  Back to dashboard
                </Button>
                <Button variant="outlined" onClick={() => window.location.reload()}>
                  Reload
                </Button>
              </Stack>
            </Stack>
          </Box>
        </ThemeProvider>
        <Scripts />
        <LiveReload />
      </body>
    </html>
  );
}
