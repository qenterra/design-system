#!/usr/bin/env node
"use strict";

const fs = require("fs");
const http = require("http");
const path = require("path");
const { chromium } = require("playwright");

const root = path.resolve(__dirname, "..");
const dist = path.join(root, "dist");
const baselineDirectory = path.join(root, "output", "screenshots");
const screenshotDirectory = path.join(root, "output", "tmp", "screenshots-current");
const reportPath = path.join(root, "output", "reports", "browser.json");
const manifestPath = path.join(root, "evidence", "screenshots.json");
const componentRegistryPath = path.join(root, "registry", "components.json");
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

async function assertComponentLab(page, baseUrl) {
  await page.setViewportSize({ width: 1280, height: 900 });
  await page.goto(`${baseUrl}/en/pages/lab.html?density=compact&width=standard#story-button-primary`, { waitUntil: "networkidle" });
  const registry = JSON.parse(fs.readFileSync(componentRegistryPath, "utf8"));
  const expectedStories = registry.components.flatMap((component) => component.stories.map((story) => `story-${component.id}-${story.id}`));
  const renderedStories = await page.locator("[data-lab-story]").evaluateAll((stories) => stories.map((story) => story.id));
  const missingStories = expectedStories.filter((story) => !renderedStories.includes(story));
  if (missingStories.length) throw new Error(`Component Lab stories are missing: ${missingStories.join(", ")}`);
  await page.locator('[data-lab-width="long"]').click();
  if (!page.url().includes("width=long")) throw new Error("Component Lab controls are not URL-addressable");
  if ((await page.locator('[data-lab-story][data-width="long"]:visible').count()) < 2) throw new Error("Pseudo-long stories are missing");
  await page.locator('[data-lab-width="rtl"]').click();
  if ((await page.locator('[data-lab-story][data-width="rtl"]:visible [dir="rtl"]').count()) < 1) throw new Error("Pseudo-RTL story is missing");
  await page.goto(`${baseUrl}/en/pages/lab.html?width=standard#story-field-invalid`, { waitUntil: "networkidle" });
  const invalid = page.locator('#story-field-invalid input[aria-invalid="true"][aria-describedby]');
  if ((await invalid.count()) !== 1) throw new Error("Invalid field story lacks accessible error wiring");
  if (await page.locator('[role="option"]:not([role="listbox"] [role="option"])').count()) {
    throw new Error("Component Lab exposes an option outside a listbox");
  }
  if (await page.locator('#story-button-loading button[aria-busy="true"][aria-disabled="true"]').count() !== 1) {
    throw new Error("Loading button story lacks busy and unavailable semantics");
  }
  const loadingAnimation = await page.locator("#story-button-loading .lab-progress").evaluate((element) => getComputedStyle(element).animationName);
  if (loadingAnimation === "none") throw new Error("Loading button story lacks a progress animation");
  if (await page.locator('#story-field-read-only input[readonly]').count() !== 1) {
    throw new Error("Read-only field story lacks the readonly contract");
  }
  await page.locator("#story-button-primary button").focus();
  const outline = await page.locator("#story-button-primary button").evaluate((element) => getComputedStyle(element).outlineStyle);
  if (outline === "none") throw new Error("Component Lab focus treatment is not visible");
}

async function assertSiteChrome(page, baseUrl) {
  await page.setViewportSize({ width: 1280, height: 900 });
  await page.goto(`${baseUrl}/en/index.html`, { waitUntil: "networkidle" });
  const search = page.locator("[data-search]");
  if (await search.getAttribute("role") !== "combobox") throw new Error("Search is not exposed as a combobox");
  await search.fill("motion");
  await page.locator('[data-search-results][role="listbox"] [role="option"]').first().waitFor();
  if (await search.getAttribute("aria-expanded") !== "true") throw new Error("Search did not expose its expanded state");
  if (await page.locator(".search-snippet mark").count() < 1) throw new Error("Search results lack contextual highlighting");
  await page.keyboard.press("ArrowDown");
  const activeDescendant = await search.getAttribute("aria-activedescendant");
  if (!activeDescendant || await page.locator(`#${activeDescendant}[aria-selected="true"]`).count() !== 1) {
    throw new Error("Search keyboard selection lacks aria-activedescendant wiring");
  }
  await page.keyboard.press("Escape");
  if (await page.locator("[data-search-results].is-open").count() || await search.getAttribute("aria-expanded") !== "false") {
    throw new Error("Escape did not close search results");
  }

  await page.setViewportSize({ width: 390, height: 844 });
  await page.reload({ waitUntil: "networkidle" });
  const sidebar = page.locator("[data-sidebar]");
  const hiddenState = await sidebar.evaluate((element) => ({ inert: element.inert, hidden: element.getAttribute("aria-hidden") }));
  if (!hiddenState.inert || hiddenState.hidden !== "true") throw new Error(`Closed mobile navigation remains accessible: ${JSON.stringify(hiddenState)}`);
  await page.locator("[data-menu-button]").click();
  const openState = await sidebar.evaluate((element) => ({ inert: element.inert, hidden: element.getAttribute("aria-hidden") }));
  if (openState.inert || openState.hidden !== "false") throw new Error(`Open mobile navigation is inaccessible: ${JSON.stringify(openState)}`);
  await page.keyboard.press("Escape");
  const closedState = await sidebar.evaluate((element) => ({ inert: element.inert, hidden: element.getAttribute("aria-hidden") }));
  if (!closedState.inert || closedState.hidden !== "true") throw new Error(`Closed mobile navigation leaked focus targets: ${JSON.stringify(closedState)}`);
  if (!await page.locator("[data-menu-button]").evaluate((element) => element === document.activeElement)) {
    throw new Error("Closing mobile navigation did not restore focus");
  }
}

async function applyCaptureState(page, entry) {
  if (entry.reducedTransparency) {
    await page.locator("html").evaluate((element) => { element.dataset.reducedTransparency = "true"; });
  }
  if (entry.state === "hover") await page.locator('[data-state="hover"] .qds-button').first().hover();
  if (entry.state === "focus") await page.locator('[data-state="focused"] .qds-button').first().focus();
}

async function capture(page, baseUrl, entry) {
  await page.setViewportSize(entry.viewport);
  await page.emulateMedia({
    colorScheme: entry.theme === "system" ? "no-preference" : entry.theme,
    reducedMotion: entry.reducedMotion ? "reduce" : "no-preference",
    contrast: entry.increasedContrast ? "more" : "no-preference",
    forcedColors: entry.forcedColors ? "active" : "none"
  });
  await page.goto(`${baseUrl}/${entry.path}`, { waitUntil: "networkidle" });
  await page.evaluate((theme) => {
    localStorage.setItem("qds-theme", theme);
    if (theme === "system") document.documentElement.removeAttribute("data-theme");
    else document.documentElement.dataset.theme = theme;
  }, entry.theme);
  await page.reload({ waitUntil: "networkidle" });
  await applyCaptureState(page, entry);
  if (entry.scrollTarget) {
    await page.locator(entry.scrollTarget).evaluate((element) => {
      document.documentElement.style.scrollBehavior = "auto";
      window.scrollTo(0, Math.max(0, element.offsetTop - 80));
    });
    await page.waitForTimeout(150);
  }
  await page.addStyleTag({
    content: "*, *::before, *::after { animation: none !important; caret-color: transparent !important; transition: none !important; }"
  });
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
    reducedTransparency: entry.reducedTransparency === true,
    increasedContrast: entry.increasedContrast === true,
    forcedColors: entry.forcedColors === true,
    state: entry.state || null,
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
  if (result.navCount !== 16 || result.invalidNav || result.invalidChrome) {
    throw new Error(`Icon family mismatch: ${JSON.stringify(result)}`);
  }
}

async function fillEmailFields(page) {
  const controls = page.locator("[data-email-field]");
  for (let index = 0; index < await controls.count(); index += 1) {
    const control = controls.nth(index);
    await control.fill((await control.getAttribute("placeholder")) || "Example");
  }
}

async function assertEmailComposer(page, baseUrl) {
  await page.setViewportSize({ width: 1280, height: 900 });
  await page.emulateMedia({ colorScheme: "dark", reducedMotion: "no-preference" });
  await page.goto(`${baseUrl}/en/pages/email.html`, { waitUntil: "networkidle" });
  if (await page.locator('[data-email-composer][data-ready="true"]').count() !== 1) {
    throw new Error("Email composer did not initialize");
  }
  if (await page.locator("[data-email-template]").count() !== 48) {
    throw new Error("Email composer does not expose 48 templates");
  }

  await page.locator("[data-email-category]").selectOption("account");
  if (await page.locator("[data-email-template]:visible").count() !== 12) {
    throw new Error("Account filter does not expose 12 templates");
  }
  await page.locator('[data-email-template="account-verify-email"]').click();
  const selectedState = await page.locator('[data-email-template="account-verify-email"]').evaluate((element) => ({
    pressed: element.getAttribute("aria-pressed"),
    current: element.getAttribute("aria-current"),
    background: getComputedStyle(element).backgroundColor,
    shadow: getComputedStyle(element).boxShadow
  }));
  const unselectedBackground = await page.locator('[data-email-template="account-sign-in-code"]').evaluate(
    (element) => getComputedStyle(element).backgroundColor
  );
  if (selectedState.pressed !== "true" || selectedState.current !== "true" ||
      selectedState.background === unselectedBackground || selectedState.shadow === "none") {
    throw new Error(`Selected email template lacks a clear current state: ${JSON.stringify(selectedState)}`);
  }
  await page.locator("[data-email-copy-rich]").click();
  if (await page.locator('[data-email-field][aria-invalid="true"]').count() === 0) {
    throw new Error("Required fields did not block copy");
  }

  await fillEmailFields(page);
  const frame = page.locator("[data-email-preview-frame]");
  await frame.waitFor({ state: "visible" });
  const source = await frame.getAttribute("srcdoc");
  if (!source || source.includes("{{") || source.includes("<script>alert")) {
    throw new Error("Email preview is unresolved or unsafe");
  }
  const lightContrast = await frame.contentFrame().locator('[data-email-title]').evaluate((element) => {
    const parse = (value) => (value.match(/[\d.]+/g) || []).slice(0, 3).map(Number);
    const luminance = (rgb) => {
      const values = rgb.map((channel) => {
        const normalized = channel / 255;
        return normalized <= 0.03928 ? normalized / 12.92 : ((normalized + 0.055) / 1.055) ** 2.4;
      });
      return 0.2126 * values[0] + 0.7152 * values[1] + 0.0722 * values[2];
    };
    const foreground = luminance(parse(getComputedStyle(element).color));
    const background = luminance(parse(getComputedStyle(element.closest('[data-email-card]')).backgroundColor));
    return (Math.max(foreground, background) + 0.05) / (Math.min(foreground, background) + 0.05);
  });
  if (lightContrast < 4.5) throw new Error(`Light email text contrast is ${lightContrast.toFixed(2)}:1`);

  await page.evaluate(() => {
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: {
        writeText: async (value) => { window.__qdsCopiedText = value; },
        write: async (items) => { window.__qdsCopiedItems = items.length; }
      }
    });
  });
  await page.locator("[data-email-copy-rich]").click();
  if (await page.evaluate(() => window.__qdsCopiedItems) !== 1) {
    throw new Error("Rich email copy did not write one clipboard item");
  }
  await page.locator("[data-email-copy-subject]").click();
  if (!(await page.evaluate(() => window.__qdsCopiedText || "")).includes("Verify")) {
    throw new Error("Subject copy did not use rendered subject");
  }

  const productValue = await page.locator('[data-email-field="productName"]').inputValue();
  const recipientValue = await page.locator('[data-email-field="recipientName"]').inputValue();
  await page.locator('[data-email-template="account-password-reset"]').click();
  if (await page.locator('[data-email-field="productName"]').inputValue() !== productValue) {
    throw new Error("Harmless product field was not retained");
  }
  if (await page.locator('[data-email-field="recipientName"]').inputValue() !== recipientValue) {
    throw new Error("A compatible filled field was lost during a template change");
  }

  await page.locator('[data-email-locale="ru"]').click();
  if ((await page.locator("html").getAttribute("lang")) !== "en") {
    throw new Error("Email language changed the page language");
  }
  if ((await page.locator("[data-email-selected-title]").textContent()) !== "Сброс пароля") {
    throw new Error("Email language did not update the selected template copy");
  }
  if ((await page.locator('[data-email-template="account-password-reset"] strong').textContent()) !== "Сброс пароля") {
    throw new Error("Email language did not update the template list");
  }
  await frame.contentFrame().locator('[data-email-title]', { hasText: "Выберите новый пароль" }).waitFor();
  if ((await page.locator('[data-email-field="recipientName"]').inputValue()) !== recipientValue) {
    throw new Error("Email language change discarded filled values");
  }
  await page.locator("[data-email-copy-subject]").click();
  if (!(await page.evaluate(() => window.__qdsCopiedText || "")).includes("Сбросьте пароль")) {
    throw new Error("Email language did not update copied output");
  }

  await page.locator("[data-email-reset]").click();
  const uncleared = await page.locator("[data-email-field]").evaluateAll((controls) => (
    controls.filter((control) => control.type === "checkbox" ? control.checked : control.value !== "").length
  ));
  if (uncleared || await page.locator("[data-email-preview-frame]:visible").count()) {
    throw new Error("Clear fields did not reset values and preview");
  }
  await page.waitForFunction(() => document.querySelector("[data-email-live]")?.textContent.includes("Fields cleared"));

  await fillEmailFields(page);
  await page.evaluate(() => Object.defineProperty(navigator, "clipboard", { configurable: true, value: undefined }));
  await page.locator("[data-email-copy-text]").click();
  if (await page.locator("[data-email-fallback]:visible").count() !== 1) {
    throw new Error("Clipboard failure did not expose manual fallback");
  }
  const emailStorageKeys = await page.evaluate(() => Object.keys(localStorage).filter((key) => key.toLowerCase().includes("email")));
  if (emailStorageKeys.length) throw new Error(`Email composer persisted data: ${emailStorageKeys.join(", ")}`);
}

async function scrollToSectionAndWaitForNavigation(page, target, slug) {
  await page.locator(target).evaluate((element) => {
    document.documentElement.style.scrollBehavior = "auto";
    window.scrollTo(0, Math.max(0, element.offsetTop - 80));
  });
  await page.waitForFunction(
    (expected) => document.querySelector(`.site-nav a[data-nav-slug="${expected}"]`)?.getAttribute("aria-current") === "location",
    slug
  );
}

async function assertScrollSpy(page, baseUrl) {
  await page.setViewportSize({ width: 1280, height: 900 });
  await page.goto(`${baseUrl}/en/qenterra-design-system.html#section-11`, { waitUntil: "networkidle" });
  await scrollToSectionAndWaitForNavigation(page, "#section-11", "motion");
  await scrollToSectionAndWaitForNavigation(page, "#section-18", "governance");
  await scrollToSectionAndWaitForNavigation(page, "#repository-overview", "repositories");
  await scrollToSectionAndWaitForNavigation(page, "#brand-overview", "brand");
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
  const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  const matrix = manifest.captures;
  if (!Array.isArray(matrix) || matrix.length === 0) throw new Error("Screenshot manifest has no captures");
  fs.rmSync(screenshotDirectory, { recursive: true, force: true });
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
    await assertSiteChrome(page, baseUrl);

    await assertUniformSvgIcons(page);
    await assertScrollSpy(page, baseUrl);
    await assertLanguagePickerPosition(page, baseUrl);
    await assertLanguageSwitch(page, baseUrl);
    await assertComponentLab(page, baseUrl);
    await assertEmailComposer(page, baseUrl);

    const captures = [];
    for (const entry of matrix) captures.push(await capture(page, baseUrl, entry));

    if (process.env.QDS_UPDATE_SCREENSHOTS === "1") {
      fs.mkdirSync(baselineDirectory, { recursive: true });
      const expected = new Set(matrix.map((entry) => `${entry.name}.png`));
      for (const filename of fs.readdirSync(baselineDirectory)) {
        if (filename.endsWith(".png") && !expected.has(filename)) fs.rmSync(path.join(baselineDirectory, filename));
      }
      for (const filename of expected) {
        fs.copyFileSync(path.join(screenshotDirectory, filename), path.join(baselineDirectory, filename));
      }
    }

    if (consoleErrors.length) throw new Error(`Browser console errors: ${consoleErrors.join(" | ")}`);
    const checks = {
      searchAndEscape: "passed",
      mobileNavigationAndEscape: "passed",
      scrollSpy: "passed",
      languageSwitch: "passed",
      languagePickerPosition: "passed",
      brandModule: "passed",
      repositoryModule: "passed",
      uniformSvgIcons: "passed",
      componentLab: "passed",
      emailComposer: "passed",
      pseudoLocalization: "passed",
      visibleFocus: "passed",
      semanticStructure: "passed",
      responsiveOverflow: "passed",
      consoleErrors: "none"
    };
    const version = fs.readFileSync(path.join(root, "VERSION"), "utf8").trim();
    fs.writeFileSync(reportPath, `${JSON.stringify({ version, manifestSchemaVersion: manifest.schemaVersion, status: "passed", checks, captures, consoleErrors }, null, 2)}\n`);
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
