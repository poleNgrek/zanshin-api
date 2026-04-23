/** @type {import("@remix-run/dev").AppConfig} */
export default {
  appDirectory: "app",
  ignoredRouteFiles: ["**/.*"],
  serverModuleFormat: "esm",
  entryClientFile: "client.tsx",
  entryServerFile: "server.tsx",
  routes(defineRoutes) {
    return defineRoutes((route) => {
      route("/", "src/routes/index.tsx");
      route("dashboard", "src/routes/index.tsx");
      route("matches", "src/routes/matches.tsx");
      route("tournaments", "src/routes/tournaments.tsx");
      route("competitors", "src/routes/competitors.tsx");
      route("analytics", "src/routes/analytics.tsx");
      route("gradings/results", "src/routes/gradings/results.tsx");

      route("admin", "src/routes/admin.tsx", () => {
        route("", "src/routes/admin/index.tsx", { index: true });
        route("tournaments", "src/routes/admin/tournaments.tsx");
        route("competitors", "src/routes/admin/competitors.tsx");
        route("analytics", "src/routes/admin/analytics.tsx");
        route("gradings/results", "src/routes/admin/gradings/results.tsx");
      });
    });
  }
};
