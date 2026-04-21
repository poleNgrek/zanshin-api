import { expect, test } from "@playwright/test";

test("homepage renders dashboard heading", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { name: "Tournament Operations Dashboard" })).toBeVisible();
});
