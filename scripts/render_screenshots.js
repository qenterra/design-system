#!/usr/bin/env node
"use strict";

const fs = require("fs");
const http = require("http");
const path = require("path");
const { chromium } = require("playwright");

const root = path.resolve(__dirname, "..");
const dist = path.join(root, "dist");
const screenshotDirectory = path.join(root, "output", "screenshots");
const reportPath = path.join(root, "output", "reports", "browser.json");

const contentTypes = {
  ".css": "text/css; charset=utf-8",
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png"
};

function startServer() {
  return new Promise((resolve, reject) => {
    const server = http.createServer((request, response) => {
      const rawPath = decodeURIComponent((request.url || "/").split("?")[0]);
      const relative = rawPath === "/" ? "index.html" : rawPath.replace(/^\/+/, "");
      const target = path.resolve(dist, relative);
      if (!target.startsWith(`${dist}${path.sep}`) && target !== path.join(dist, "index.html")) {
        response.writeHead(403).end("Forbidden");
        return;
      }
      fs.readFile(target, (error, data) => {
        if (error) {
          response.writeHead(404).end("Not found");
          return;
        }
        response.writeHead(200, { "Content-Type": contentTypes[path.extname(target)] || "application/octet-stream" });
        response.end(data);
      });
    });
    server.once("error", reject);
    server.listen(0, "127.0.0.1", () => resolve(server));
  });
}

async function assertNoOverflow(page, label) {
  const result = await page.evaluate(() => ({
    scrollWidth: document.documentElement.scrollWidth,
    clientWidth: document.documentElement.clientWidth
  }));
  if (result.scrollWidth > result.clientWidth + 1) {
    throw new Error(`${label}: horizontal overflow ${result.scrollWidth}px > ${result.clientWidth}px`);
  }
}

async function assertAccessibleStructure(page, label) {
  const result = await page.evaluate(() => {
    const interactive = Array.from(document.querySelectorAll("button, a[href], input, select, textarea"));
    const unnamed = interactive
      .filter((element) => {
        const text = (element.textContent || "").trim();
        const hasAssociatedLabel = "labels" in element && element.labels && element.labels.length > 0;
        return !text && !hasAssociatedLabel && !element.getAttribute("aria-label") && !element.getAttribute("title");
      })
      .map((element) => element.outerHTML.slice(0, 120));
    const headings = Array.from(document.querySelectorAll("h1, h2, h3, h4, h5, h6")).map((heading) => Number(heading.tagName[1]));
    const skipped = headings.some((level, index) => index > 0 && level > headings[index - 1] + 1);
    return { h1: document.querySelectorAll("h1").length, unnamed, skipped };
  });
  if (result.h1 !== 1) throw new Error(`${label}: expected exactly one h1, got ${result.h1}`);
  if (result.unnamed.length) throw new Error(`${label}: unnamed interactive elements: ${result.unnamed.join(" | ")}`);
  if (result.skipped) throw new Error(`${label}: skipped heading level`);
}

async function capture(page, baseUrl, entry) {
  await page.setViewportSize(entry.viewport);
  await page.emulateMedia({ colorScheme: entry.theme === "dark" ? "dark" : "light", reducedMotion: entry.reducedMotion ? "reduce" : "no-preference" });
  await page.goto(`${baseUrl}/${entry.path}`, { waitUntil: "networkidle" });
  await page.evaluate((theme) => {
    localStorage.setItem("qds-theme", theme);
    if (theme === "system") document.documentElement.removeAttribute("data-theme");
    else document.documentElement.dataset.theme = theme;
  }, entry.theme);
  await page.reload({ waitUntil: "networkidle" });
  await assertNoOverflow(page, entry.name);
  await assertAccessibleStructure(page, entry.name);
  const main = page.locator("main");
  if ((await main.count()) !== 1) throw new Error(`${entry.name}: expected one main landmark`);
  await page.screenshot({ path: path.join(screenshotDirectory, `${entry.name}.png`), fullPage: true });
  return {
    name: entry.name,
    path: entry.path,
    viewport: entry.viewport,
    theme: entry.theme,
    reducedMotion: entry.reducedMotion,
    title: await page.title(),
    sections: await page.locator(".doc-section").count(),
    structure: {
      oneH1: true,
      namedInteractiveElements: true,
      sequentialHeadingLevels: true,
      oneMainLandmark: true,
      noHorizontalOverflow: true
    }
  };
}

async function main() {
  fs.mkdirSync(screenshotDirectory, { recursive: true });
  fs.mkdirSync(path.dirname(reportPath), { recursive: true });
  const server = await startServer();
  const address = server.address();
  const port = typeof address === "object" && address ? address.port : 0;
  const baseUrl = `http://127.0.0.1:${port}`;
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  const consoleErrors = [];
  page.on("console", (message) => {
    if (message.type() === "error") consoleErrors.push(message.text());
  });
  page.on("pageerror", (error) => consoleErrors.push(error.message));

  try {
    await page.goto(`${baseUrl}/`, { waitUntil: "networkidle" });
    await page.locator("[data-search]").fill("motion");
    await page.locator("[data-search-results] .search-result").first().waitFor();
    await page.keyboard.press("Escape");
    if (await page.locator("[data-search-results].is-open").count()) {
      throw new Error("Escape did not close search results");
    }

    await page.setViewportSize({ width: 390, height: 844 });
    await page.reload({ waitUntil: "networkidle" });
    await page.locator("[data-menu-button]").click();
    if (!(await page.locator("body.nav-open").count())) throw new Error("Mobile navigation did not open");
    await page.keyboard.press("Escape");
    if (await page.locator("body.nav-open").count()) throw new Error("Escape did not close mobile navigation");

    const captures = [];
    const matrix = [
      { name: "overview-dark-wide", path: "index.html", viewport: { width: 1440, height: 1000 }, theme: "dark", reducedMotion: false },
      { name: "foundations-light-desktop", path: "pages/foundations.html", viewport: { width: 1280, height: 900 }, theme: "light", reducedMotion: false },
      { name: "components-dark-mobile", path: "pages/components.html", viewport: { width: 390, height: 844 }, theme: "dark", reducedMotion: true },
      { name: "products-light-tablet", path: "pages/products.html", viewport: { width: 768, height: 1024 }, theme: "light", reducedMotion: false },
      { name: "standalone-dark-desktop", path: "qenterra-design-system.html", viewport: { width: 1280, height: 900 }, theme: "dark", reducedMotion: true }
    ];
    for (const entry of matrix) captures.push(await capture(page, baseUrl, entry));

    if (consoleErrors.length) throw new Error(`Browser console errors: ${consoleErrors.join(" | ")}`);
    const checks = {
      searchAndEscape: "passed",
      mobileNavigationAndEscape: "passed",
      semanticStructure: "passed",
      responsiveOverflow: "passed",
      consoleErrors: "none"
    };
    fs.writeFileSync(reportPath, `${JSON.stringify({ status: "passed", checks, captures, consoleErrors }, null, 2)}\n`);
    process.stdout.write(`Rendered ${captures.length} screenshots with no browser errors.\n`);
  } finally {
    await browser.close();
    await new Promise((resolve) => server.close(resolve));
  }
}

main().catch((error) => {
  process.stderr.write(`${error.stack || error.message}\n`);
  process.exitCode = 1;
});
