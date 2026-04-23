import { expect, test } from "@playwright/test";

const realApiEnabled = process.env.PLAYWRIGHT_REAL_API === "1";

test.skip(!realApiEnabled, "Real API integration lane disabled");

test("matches page loads against real API without route mocks", async ({ page }) => {
  await page.goto("/matches");
  await expect(page.getByRole("heading", { name: "Match List" })).toBeVisible();

  const emptyState = page.getByText("No matches available for the selected filters.");
  const seededMatch = page.getByText(/Kenshi Alpha vs Kenshi Beta/);

  if (await emptyState.isVisible().catch(() => false)) {
    await expect(emptyState).toBeVisible();
  } else {
    await expect(seededMatch).toBeVisible();
  }
});
