import { expect, test } from "@playwright/test";

import { fixtureData, fixtureIds } from "./fixtures";

test("admin console route renders", async ({ page }) => {
  await page.goto("/admin");
  await expect(page.getByRole("heading", { name: "Admin Console" })).toBeVisible();
});

test("admin tournaments route supports create flow with mocked API", async ({ page }) => {
  const tournaments = [{ ...fixtureData.tournament }];

  await page.route("**/api/v1/tournaments", async (route) => {
    if (route.request().method() === "GET") {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({ data: tournaments })
      });
      return;
    }

    const payload = route.request().postDataJSON() as { name?: string; starts_on?: string };
    const created = {
      id: "9e6d81f8-bf55-4faa-94f3-7b8f3e35b091",
      name: payload.name ?? "Created Tournament",
      location: fixtureData.tournament.location,
      starts_on: payload.starts_on ?? fixtureData.tournament.starts_on
    };
    tournaments.unshift(created);

    await route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify({ data: created })
    });
  });

  await page.route("**/api/v1/divisions**", async (route) => {
    await route.fulfill({
      status: route.request().method() === "GET" ? 200 : 201,
      contentType: "application/json",
      body:
        route.request().method() === "GET"
          ? JSON.stringify({ data: [fixtureData.division] })
          : JSON.stringify({ data: fixtureData.division })
    });
  });

  await page.route("**/api/v1/gradings/sessions**", async (route) => {
    await route.fulfill({
      status: route.request().method() === "GET" ? 200 : 201,
      contentType: "application/json",
      body:
        route.request().method() === "GET"
          ? JSON.stringify({ data: [fixtureData.gradingSession] })
          : JSON.stringify({ data: fixtureData.gradingSession })
    });
  });

  await page.goto("/admin/tournaments");
  await expect(page.getByRole("heading", { name: "Tournaments" })).toBeVisible();

  await page.getByLabel("Tournament name").fill("Autumn Open");
  await page.getByRole("button", { name: "Create" }).first().click();

  await expect(page.getByText(`Autumn Open (`)).toBeVisible();
});

test("admin competitors route supports create flow with mocked API", async ({ page }) => {
  const competitors = [...fixtureData.competitors];

  await page.route("**/api/v1/competitors", async (route) => {
    if (route.request().method() === "GET") {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({ data: competitors })
      });
      return;
    }

    const payload = route.request().postDataJSON() as { display_name?: string };
    const created = {
      id: "8d2a8874-c20f-47e5-b3b1-4d3f8916f123",
      display_name: payload.display_name ?? "Created Competitor",
      federation_id: null
    };
    competitors.unshift(created);

    await route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify({ data: created })
    });
  });

  await page.goto("/admin/competitors");
  await expect(page.getByRole("heading", { name: "Competitors" })).toBeVisible();

  await page.getByLabel("Display name").fill("Kenshi Three");
  await page.getByRole("button", { name: "Create" }).click();

  await expect(page.getByText("Kenshi Three")).toBeVisible();
});

test("admin grading results route supports create, compute and finalize", async ({ page }) => {
  let createCalled = false;
  let computeCalled = false;
  let finalizeCalled = false;

  const results = [{ ...fixtureData.gradingResult }];

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
      body: JSON.stringify({ data: fixtureData.competitors })
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
        body: JSON.stringify({ data: results })
      });
      return;
    }

    createCalled = true;
    results.unshift({ ...fixtureData.gradingResult, id: "b9d3fcc0-e2ad-446f-9158-d0be8660a221" });
    await route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify({ data: results[0] })
    });
  });

  await page.route("**/api/v1/gradings/results/*/compute", async (route) => {
    computeCalled = true;
    results[0] = { ...results[0], ...fixtureData.gradingComputedResult };
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({ data: results[0] })
    });
  });

  await page.route("**/api/v1/gradings/results/*/finalize", async (route) => {
    finalizeCalled = true;
    results[0] = { ...results[0], ...fixtureData.gradingFinalizedResult };
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({ data: results[0] })
    });
  });

  await page.goto("/admin/gradings/results");
  await expect(page.getByRole("heading", { name: "Grading Results" })).toBeVisible();

  await page.getByRole("button", { name: "Load Results" }).click();
  await expect(page.getByText("4dan - pending")).toBeVisible();

  await page.getByRole("button", { name: "Create Result" }).click();
  await page.getByRole("button", { name: "Compute" }).first().click();
  await page.getByRole("button", { name: "Finalize" }).first().click();

  expect(createCalled).toBeTruthy();
  expect(computeCalled).toBeTruthy();
  expect(finalizeCalled).toBeTruthy();

  await expect(page.getByText(fixtureIds.gradingResult)).toBeVisible();
});
