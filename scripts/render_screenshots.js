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
const systemChrome = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

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
  if (entry.scrollTarget) {
    await page.locator(entry.scrollTarget).evaluate((element) => {
      document.documentElement.style.scrollBehavior = "auto";
      window.scrollTo(0, Math.max(0, element.offsetTop - 80));
    });
    await page.waitForTimeout(150);
  }
  await assertNoOverflow(page, entry.name);
  await assertAccessibleStructure(page, entry.name);
  const main = page.locator("main");
  if ((await main.count()) !== 1) throw new Error(`${entry.name}: expected one main landmark`);
  await page.screenshot({
    path: path.join(screenshotDirectory, `${entry.name}.png`),
    fullPage: entry.fullPage !== false
  });
  return {
    name: entry.name,
    path: entry.path,
    viewport: entry.viewport,
    theme: entry.theme,
    reducedMotion: entry.reducedMotion,
    locale: await page.locator("html").getAttribute("lang"),
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

async function assertUniformSvgIcons(page) {
  const result = await page.evaluate(() => {
    const navGlyphs = Array.from(document.querySelectorAll(".nav-glyph"));
    const chromeControls = Array.from(document.querySelectorAll(".language-button, .menu-button, .search-icon"));
    return {
      navCount: navGlyphs.length,
      invalidNav: navGlyphs.filter((glyph) => glyph.querySelectorAll("svg.icon").length !== 1 || (glyph.textContent || "").trim()).length,
      invalidChrome: chromeControls.filter((control) => control.querySelectorAll("svg.icon").length !== 1).length
    };
  });
  if (result.navCount !== 12 || result.invalidNav || result.invalidChrome) {
    throw new Error(`Icon family mismatch: ${JSON.stringify(result)}`);
  }
}

async function assertScrollSpy(page, baseUrl) {
  await page.setViewportSize({ width: 1280, height: 900 });
  await page.goto(`${baseUrl}/en/qenterra-design-system.html#section-11`, { waitUntil: "networkidle" });
  await page.locator("#section-11").evaluate((element) => {
    document.documentElement.style.scrollBehavior = "auto";
    window.scrollTo(0, Math.max(0, element.offsetTop - 80));
  });
  await page.waitForTimeout(150);
  const motionCurrent = await page.locator('.site-nav a[data-nav-slug="motion"][aria-current="location"]').count();
  if (motionCurrent !== 1) throw new Error("Scroll-spy did not activate Motion at section 11");

  await page.locator("#section-18").evaluate((element) => window.scrollTo(0, Math.max(0, element.offsetTop - 80)));
  await page.waitForTimeout(150);
  const governanceCurrent = await page.locator('.site-nav a[data-nav-slug="governance"][aria-current="location"]').count();
  if (governanceCurrent !== 1) throw new Error("Scroll-spy did not activate Governance at section 18");

  await page.locator("#repository-overview").evaluate((element) => window.scrollTo(0, Math.max(0, element.offsetTop - 80)));
  await page.waitForTimeout(150);
  const repositoryCurrent = await page.locator('.site-nav a[data-nav-slug="repositories"][aria-current="location"]').count();
  if (repositoryCurrent !== 1) throw new Error("Scroll-spy did not activate Repository documentation");
}

async function assertLanguagePickerPosition(page, baseUrl) {
  await page.setViewportSize({ width: 1280, height: 900 });
  await page.goto(`${baseUrl}/en/index.html`, { waitUntil: "networkidle" });
  const desktop = await page.evaluate(() => {
    const picker = document.querySelector(".topbar > .language-picker");
    const sidebarPicker = document.querySelector(".sidebar .language-picker");
    const topbar = document.querySelector(".topbar");
    if (!picker || !topbar) return { present: false };
    const pickerBox = picker.getBoundingClientRect();
    const topbarBox = topbar.getBoundingClientRect();
    return {
      present: true,
      sidebarAbsent: !sidebarPicker,
      alignedRight: Math.abs(pickerBox.right - topbarBox.right) <= 64,
      insideViewport: pickerBox.right <= innerWidth && pickerBox.left >= 0
    };
  });
  if (!desktop.present || !desktop.sidebarAbsent || !desktop.alignedRight || !desktop.insideViewport) {
    throw new Error(`Desktop language picker is not in the upper-right top bar: ${JSON.stringify(desktop)}`);
  }

  await page.setViewportSize({ width: 390, height: 844 });
  await page.reload({ waitUntil: "networkidle" });
  await page.locator("[data-language-button]").click();
  const mobile = await page.locator("[data-language-menu]").evaluate((menu) => {
    const box = menu.getBoundingClientRect();
    return { left: box.left, right: box.right, width: innerWidth };
  });
  if (mobile.left < 0 || mobile.right > mobile.width) {
    throw new Error(`Mobile language menu leaves viewport: ${JSON.stringify(mobile)}`);
  }
  await page.keyboard.press("Escape");
}

async function assertLanguageSwitch(page, baseUrl) {
  await page.setViewportSize({ width: 1280, height: 900 });
  await page.goto(`${baseUrl}/en/pages/components.html#section-6`, { waitUntil: "networkidle" });
  await page.locator("[data-language-button]").click();
  await page.locator('[data-locale-target="ru"]').click();
  await page.waitForURL(/\/ru\/pages\/components\.html#section-6$/);
  const state = await page.evaluate(() => ({
    lang: document.documentElement.lang,
    heading: document.querySelector(".page-intro h1")?.textContent?.trim(),
    hash: location.hash,
    stored: localStorage.getItem("qds-locale")
  }));
  if (state.lang !== "ru" || state.heading !== "Компоненты" || state.hash !== "#section-6" || state.stored !== "ru") {
    throw new Error(`Language switch lost locale, page, or fragment: ${JSON.stringify(state)}`);
  }

  const button = page.locator("[data-language-button]");
  await button.focus();
  await page.keyboard.press("ArrowDown");
  await page.keyboard.press("Escape");
  const menuHidden = await page.locator("[data-language-menu]").getAttribute("hidden");
  const focused = await button.evaluate((element) => element === document.activeElement);
  if (menuHidden === null || !focused) throw new Error("Language menu Escape behavior or focus restoration failed");

  await page.goto(`${baseUrl}/en/pages/repositories.html#repository-verification`, { waitUntil: "networkidle" });
  await page.locator("[data-language-button]").click();
  await page.locator('[data-locale-target="ru"]').click();
  await page.waitForURL(/\/ru\/pages\/repositories\.html#repository-verification$/);
  if ((await page.locator("html").getAttribute("lang")) !== "ru") {
    throw new Error("Repository module language switch lost its locale");
  }
}

async function main() {
  fs.mkdirSync(screenshotDirectory, { recursive: true });
  fs.mkdirSync(path.dirname(reportPath), { recursive: true });
  const server = await startServer();
  const address = server.address();
  const port = typeof address === "object" && address ? address.port : 0;
  const baseUrl = `http://127.0.0.1:${port}`;
  const requestedBrowser = process.env.QDS_CHROMIUM_PATH;
  const executablePath = requestedBrowser || (fs.existsSync(systemChrome) ? systemChrome : undefined);
  const browser = await chromium.launch({ headless: true, executablePath });
  const page = await browser.newPage();
  const consoleErrors = [];
  page.on("console", (message) => {
    if (message.type() === "error") consoleErrors.push(message.text());
  });
  page.on("pageerror", (error) => consoleErrors.push(error.message));

  try {
    await page.goto(`${baseUrl}/en/index.html`, { waitUntil: "networkidle" });
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

    await assertUniformSvgIcons(page);
    await assertScrollSpy(page, baseUrl);
    await assertLanguagePickerPosition(page, baseUrl);
    await assertLanguageSwitch(page, baseUrl);

    const captures = [];
    const matrix = [
      { name: "overview-en-dark-wide", path: "en/index.html", viewport: { width: 1440, height: 1000 }, theme: "dark", reducedMotion: false },
      { name: "foundations-ru-light-desktop", path: "ru/pages/foundations.html", viewport: { width: 1280, height: 900 }, theme: "light", reducedMotion: false },
      { name: "components-en-dark-mobile", path: "en/pages/components.html", viewport: { width: 390, height: 844 }, theme: "dark", reducedMotion: true },
      { name: "products-ru-light-tablet", path: "ru/pages/products.html", viewport: { width: 768, height: 1024 }, theme: "light", reducedMotion: false },
      { name: "standalone-en-dark-desktop", path: "en/qenterra-design-system.html", viewport: { width: 1280, height: 900 }, theme: "dark", reducedMotion: true },
      { name: "standalone-ru-motion-dark", path: "ru/qenterra-design-system.html", viewport: { width: 1280, height: 900 }, theme: "dark", reducedMotion: false, scrollTarget: "#section-11", fullPage: false }
      ,{ name: "repositories-ru-light-desktop", path: "ru/pages/repositories.html", viewport: { width: 1280, height: 900 }, theme: "light", reducedMotion: false, scrollTarget: "#repository-verification", fullPage: false }
    ];
    for (const entry of matrix) captures.push(await capture(page, baseUrl, entry));

    if (consoleErrors.length) throw new Error(`Browser console errors: ${consoleErrors.join(" | ")}`);
    const checks = {
      searchAndEscape: "passed",
      mobileNavigationAndEscape: "passed",
      scrollSpy: "passed",
      languageSwitch: "passed",
      languagePickerPosition: "passed",
      repositoryModule: "passed",
      uniformSvgIcons: "passed",
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
