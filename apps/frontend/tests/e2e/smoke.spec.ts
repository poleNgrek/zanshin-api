import { expect, test } from "@playwright/test";
import { fixtureData, fixtureIds } from "./fixtures";

test("homepage renders dashboard heading", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { name: "Tournament Dashboard" })).toBeVisible();
});

test("tournaments page renders seeded tournaments from API", async ({ page }) => {
  await page.route("**/api/v1/tournaments", async (route) => {
    if (route.request().method() === "GET") {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          data: [fixtureData.tournament]
        })
      });
      return;
    }

    await route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify({
        data: {
          id: "1f6eeaab-5165-4634-87da-2d4ad8f8f95f",
          name: "New Tournament",
          location: null,
          starts_on: null
        }
      })
    });
  });

  await page.route("**/api/v1/divisions**", async (route) => {
    if (route.request().method() === "GET") {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({ data: [] })
      });
      return;
    }

    await route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify({
        data: {
          ...fixtureData.division,
          id: "3e34a8ec-25ad-42fe-8945-06f48166f7f3"
        }
      })
    });
  });

  await page.route("**/api/v1/gradings/sessions**", async (route) => {
    if (route.request().method() === "GET") {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({ data: [] })
      });
      return;
    }

    await route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify({
        data: {
          id: "074f6e40-1f37-4a93-b4b3-3fe96953e90d",
          tournament_id: fixtureIds.tournament,
          name: "Spring Shinsa",
          held_on: null,
          written_required: true
        }
      })
    });
  });

  await page.goto("/tournaments");
  await expect(page.getByText(`Spring Cup (${fixtureIds.tournament})`)).toBeVisible();
  await expect(page.getByRole("heading", { name: "Division Setup" })).toBeVisible();
});

test("grading results page loads session and result data", async ({ page }) => {
  await page.route("**/api/v1/tournaments", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        data: [{ ...fixtureData.tournament, starts_on: null }]
      })
    });
  });

  await page.route("**/api/v1/competitors", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        data: [fixtureData.competitors[0]]
      })
    });
  });

  await page.route("**/api/v1/gradings/sessions**", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        data: [fixtureData.gradingSession]
      })
    });
  });

  await page.route("**/api/v1/gradings/sessions/*/results", async (route) => {
    if (route.request().method() === "GET") {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          data: [fixtureData.gradingResult]
        })
      });
      return;
    }

    await route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify({
        data: fixtureData.gradingResult
      })
    });
  });

  await page.route("**/api/v1/gradings/results/*/compute", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        data: fixtureData.gradingComputedResult
      })
    });
  });

  await page.route("**/api/v1/gradings/results/*/finalize", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        data: fixtureData.gradingFinalizedResult
      })
    });
  });

  await page.goto("/gradings/results");
  await expect(page.getByText("Kenshi One")).toBeVisible();
  await page.getByRole("button", { name: "Load Results" }).click();
  await expect(page.getByText("4dan - pending")).toBeVisible();
});

test("matches page renders consumer match list", async ({ page }) => {
  await page.route("**/api/v1/matches", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        data: [fixtureData.match]
      })
    });
  });

  await page.route("**/api/v1/tournaments", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        data: [{ ...fixtureData.tournament, starts_on: null }]
      })
    });
  });

  await page.route("**/api/v1/divisions**", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        data: [fixtureData.division]
      })
    });
  });

  await page.route("**/api/v1/competitors", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        data: fixtureData.competitors
      })
    });
  });

  await page.goto("/matches");
  await expect(page.getByRole("heading", { name: "Match List" })).toBeVisible();
  await expect(page.getByText("Kenshi One vs Kenshi Two - scheduled")).toBeVisible();
});
