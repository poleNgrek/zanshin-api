import type { LinksFunction } from "@remix-run/node";
import { Links, LiveReload, Meta, Outlet, Scripts, ScrollRestoration } from "@remix-run/react";
import CssBaseline from "@mui/material/CssBaseline";
import { ThemeProvider, createTheme } from "@mui/material/styles";

import { AppShell } from "@zanshin/components";
import stylesheet from "~/styles.css";

export const links: LinksFunction = () => [{ rel: "stylesheet", href: stylesheet }];

const theme = createTheme({
  palette: {
    mode: "light",
    primary: { main: "#1f4b99" },
    secondary: { main: "#c28b1e" }
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
