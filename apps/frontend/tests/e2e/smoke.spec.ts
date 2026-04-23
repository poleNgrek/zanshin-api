import { expect, test } from "@playwright/test";

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
          data: [
            {
              id: "d4499989-6f77-4466-9c47-5205156f0ed6",
              name: "Spring Cup",
              location: "Kyoto",
              starts_on: "2026-05-20"
            }
          ]
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
          id: "3e34a8ec-25ad-42fe-8945-06f48166f7f3",
          tournament_id: "d4499989-6f77-4466-9c47-5205156f0ed6",
          name: "Adult Individual",
          format: "bracket"
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
          tournament_id: "d4499989-6f77-4466-9c47-5205156f0ed6",
          name: "Spring Shinsa",
          held_on: null,
          written_required: true
        }
      })
    });
  });

  await page.goto("/tournaments");
  await expect(page.getByText("Spring Cup (d4499989-6f77-4466-9c47-5205156f0ed6)")).toBeVisible();
  await expect(page.getByRole("heading", { name: "Division Setup" })).toBeVisible();
});

test("grading results page loads session and result data", async ({ page }) => {
  await page.route("**/api/v1/tournaments", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        data: [{ id: "d4499989-6f77-4466-9c47-5205156f0ed6", name: "Spring Cup", starts_on: null }]
      })
    });
  });

  await page.route("**/api/v1/competitors", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        data: [{ id: "22f36686-cc3a-478c-a5a1-7a58faec1e9f", display_name: "Kenshi One" }]
      })
    });
  });

  await page.route("**/api/v1/gradings/sessions**", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        data: [{ id: "1fc86665-4dd6-4f3c-af3a-faf9c746d70f", tournament_id: "d4499989-6f77-4466-9c47-5205156f0ed6", name: "Spring Shinsa" }]
      })
    });
  });

  await page.route("**/api/v1/gradings/sessions/*/results", async (route) => {
    if (route.request().method() === "GET") {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          data: [
            {
              id: "bc178577-233f-40a7-a0d1-a53bb8ff3636",
              grading_session_id: "1fc86665-4dd6-4f3c-af3a-faf9c746d70f",
              competitor_id: "22f36686-cc3a-478c-a5a1-7a58faec1e9f",
              target_grade: "4dan",
              final_result: "pending",
              jitsugi_result: "not_attempted",
              kata_result: "not_attempted",
              written_result: "not_attempted"
            }
          ]
        })
      });
      return;
    }

    await route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify({
        data: {
          id: "bc178577-233f-40a7-a0d1-a53bb8ff3636",
          grading_session_id: "1fc86665-4dd6-4f3c-af3a-faf9c746d70f",
          competitor_id: "22f36686-cc3a-478c-a5a1-7a58faec1e9f",
          target_grade: "4dan",
          final_result: "pending",
          jitsugi_result: "not_attempted",
          kata_result: "not_attempted",
          written_result: "not_attempted"
        }
      })
    });
  });

  await page.route("**/api/v1/gradings/results/*/compute", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        data: {
          id: "bc178577-233f-40a7-a0d1-a53bb8ff3636",
          grading_session_id: "1fc86665-4dd6-4f3c-af3a-faf9c746d70f",
          competitor_id: "22f36686-cc3a-478c-a5a1-7a58faec1e9f",
          target_grade: "4dan",
          final_result: "pending",
          jitsugi_result: "pass",
          kata_result: "not_attempted",
          written_result: "not_attempted"
        }
      })
    });
  });

  await page.route("**/api/v1/gradings/results/*/finalize", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        data: {
          id: "bc178577-233f-40a7-a0d1-a53bb8ff3636",
          grading_session_id: "1fc86665-4dd6-4f3c-af3a-faf9c746d70f",
          competitor_id: "22f36686-cc3a-478c-a5a1-7a58faec1e9f",
          target_grade: "4dan",
          final_result: "pending",
          jitsugi_result: "pass",
          kata_result: "not_attempted",
          written_result: "not_attempted",
          locked_at: "2026-04-21T12:00:00Z"
        }
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
        data: [
          {
            id: "b06e1842-c8ef-49f6-bbd5-d22f0dd96078",
            tournament_id: "d4499989-6f77-4466-9c47-5205156f0ed6",
            division_id: "9583d485-a8f6-4918-b8ca-a89b5838c7ac",
            aka_competitor_id: "22f36686-cc3a-478c-a5a1-7a58faec1e9f",
            shiro_competitor_id: "cad9d450-e970-48f7-abcc-b494a9532474",
            state: "scheduled",
            inserted_at: "2026-04-21T09:44:00Z"
          }
        ]
      })
    });
  });

  await page.route("**/api/v1/tournaments", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        data: [{ id: "d4499989-6f77-4466-9c47-5205156f0ed6", name: "Spring Cup", starts_on: null }]
      })
    });
  });

  await page.route("**/api/v1/divisions**", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        data: [
          {
            id: "9583d485-a8f6-4918-b8ca-a89b5838c7ac",
            tournament_id: "d4499989-6f77-4466-9c47-5205156f0ed6",
            name: "Adult Individual",
            format: "bracket"
          }
        ]
      })
    });
  });

  await page.route("**/api/v1/competitors", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        data: [
          { id: "22f36686-cc3a-478c-a5a1-7a58faec1e9f", display_name: "Kenshi One" },
          { id: "cad9d450-e970-48f7-abcc-b494a9532474", display_name: "Kenshi Two" }
        ]
      })
    });
  });

  await page.goto("/matches");
  await expect(page.getByRole("heading", { name: "Match List" })).toBeVisible();
  await expect(page.getByText("Kenshi One vs Kenshi Two - scheduled")).toBeVisible();
});
