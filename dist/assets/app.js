(function () {
  "use strict";

  const body = document.body;
  const root = body.dataset.root || "";
  const siteRoot = body.dataset.siteRoot || "";
  const locale = body.dataset.locale || "en";
  const standalone = body.dataset.standalone === "true";
  const searchInput = document.querySelector("[data-search]");
  const searchResults = document.querySelector("[data-search-results]");
  const searchStatus = document.querySelector("[data-search-status]");
  const menuButton = document.querySelector("[data-menu-button]");
  const sidebar = document.querySelector("[data-sidebar]");
  const scrim = document.querySelector("[data-scrim]");
  const progress = document.querySelector("[data-progress]");
  const languageButton = document.querySelector("[data-language-button]");
  const languageMenu = document.querySelector("[data-language-menu]");
  const themeButtons = Array.from(document.querySelectorAll("[data-theme-choice]"));
  const navigationLinks = Array.from(document.querySelectorAll(".site-nav a[data-nav-slug]"));
  const trackedSections = Array.from(document.querySelectorAll(".doc-section[data-nav-slug]"));
  const componentLab = document.querySelector(".component-lab");
  const labDensityButtons = Array.from(document.querySelectorAll("[data-lab-density]"));
  const labWidthButtons = Array.from(document.querySelectorAll("[data-lab-width]"));
  let searchIndex = window.QDS_SEARCH_INDEX || [];
  let activeResult = -1;
  let menuReturnTarget = null;
  let scrollFrame = 0;

  function applyTheme(choice, persist) {
    if (choice === "system") document.documentElement.removeAttribute("data-theme");
    else document.documentElement.dataset.theme = choice;
    themeButtons.forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.themeChoice === choice));
    });
    if (persist) localStorage.setItem("qds-theme", choice);
  }

  function currentTheme() {
    return localStorage.getItem("qds-theme") || "system";
  }

  function openNavigation() {
    menuReturnTarget = document.activeElement;
    if (sidebar) {
      sidebar.inert = false;
      sidebar.setAttribute("aria-hidden", "false");
    }
    body.classList.add("nav-open");
    menuButton?.setAttribute("aria-expanded", "true");
    document.querySelector(".site-nav a")?.focus();
  }

  function closeNavigation(restoreFocus) {
    if (restoreFocus && menuReturnTarget instanceof HTMLElement) menuReturnTarget.focus();
    body.classList.remove("nav-open");
    menuButton?.setAttribute("aria-expanded", "false");
    if (sidebar && window.matchMedia("(max-width: 920px)").matches) {
      sidebar.inert = true;
      sidebar.setAttribute("aria-hidden", "true");
    }
  }

  function synchronizeNavigationAvailability() {
    if (!sidebar) return;
    const mobile = window.matchMedia("(max-width: 920px)").matches;
    const hidden = mobile && !body.classList.contains("nav-open");
    sidebar.inert = hidden;
    sidebar.setAttribute("aria-hidden", String(hidden));
  }

  function openLanguageMenu() {
    if (!languageMenu || !languageButton) return;
    languageMenu.hidden = false;
    languageButton.setAttribute("aria-expanded", "true");
  }

  function closeLanguageMenu(restoreFocus) {
    if (!languageMenu || !languageButton) return;
    languageMenu.hidden = true;
    languageButton.setAttribute("aria-expanded", "false");
    if (restoreFocus) languageButton.focus();
  }

  function moveLanguageFocus(direction) {
    if (!languageMenu) return;
    const links = Array.from(languageMenu.querySelectorAll("a"));
    if (!links.length) return;
    const current = Math.max(0, links.indexOf(document.activeElement));
    links[(current + direction + links.length) % links.length].focus();
  }

  function normalized(value) {
    return value.toLocaleLowerCase(locale).trim();
  }

  function closeSearch() {
    if (!searchResults) return;
    searchResults.classList.remove("is-open");
    searchResults.replaceChildren();
    searchInput?.setAttribute("aria-expanded", "false");
    searchInput?.removeAttribute("aria-activedescendant");
    if (searchStatus) searchStatus.textContent = "";
    activeResult = -1;
  }

  function appendHighlightedText(target, text, query) {
    const normalizedText = normalized(text);
    const start = normalizedText.indexOf(query);
    if (start < 0) {
      target.append(document.createTextNode(text));
      return;
    }
    target.append(document.createTextNode(text.slice(0, start)));
    const mark = document.createElement("mark");
    mark.textContent = text.slice(start, start + query.length);
    target.append(mark, document.createTextNode(text.slice(start + query.length)));
  }

  function searchSnippet(text, query) {
    const clean = String(text || "").replace(/\s+/g, " ").trim();
    const match = normalized(clean).indexOf(query);
    const start = Math.max(0, match < 0 ? 0 : match - 54);
    const end = Math.min(clean.length, start + 128);
    return `${start > 0 ? "…" : ""}${clean.slice(start, end)}${end < clean.length ? "…" : ""}`;
  }

  function resultUrl(item) {
    const anchor = item.anchor || `section-${item.section}`;
    if (standalone) return `#${anchor}`;
    return `${siteRoot}${item.path}#${anchor}`;
  }

  function renderSearch(query) {
    if (!searchResults) return;
    const value = normalized(query);
    searchResults.replaceChildren();
    activeResult = -1;
    if (value.length < 2) {
      closeSearch();
      return;
    }

    const matches = searchIndex
      .map((item) => {
        const title = normalized(item.title);
        const page = normalized(item.page);
        const text = normalized(item.text);
        const score = title.startsWith(value) ? 0 : title.includes(value) ? 1 : page.includes(value) ? 2 : text.includes(value) ? 3 : 99;
        return { item, score };
      })
      .filter((entry) => entry.score < 99)
      .sort((a, b) => a.score - b.score || (a.item.order ?? 0) - (b.item.order ?? 0))
      .slice(0, 10);

    if (!matches.length) {
      const empty = document.createElement("div");
      empty.className = "search-empty";
      empty.setAttribute("role", "option");
      empty.setAttribute("aria-disabled", "true");
      empty.textContent = body.dataset.searchEmpty || "No matching section.";
      searchResults.append(empty);
    } else {
      matches.forEach(({ item }, index) => {
        const link = document.createElement("a");
        link.className = "search-result";
        link.id = `qds-search-result-${index}`;
        link.setAttribute("role", "option");
        link.setAttribute("aria-selected", "false");
        link.href = resultUrl(item);
        const title = document.createElement("strong");
        appendHighlightedText(title, item.title, value);
        const meta = document.createElement("span");
        meta.textContent = `${item.page} · ${body.dataset.sectionLabel || "Section"} ${item.section}`;
        const snippet = document.createElement("small");
        snippet.className = "search-snippet";
        appendHighlightedText(snippet, searchSnippet(item.text, value), value);
        link.append(title, meta, snippet);
        link.addEventListener("click", closeSearch);
        searchResults.append(link);
      });
    }
    searchResults.classList.add("is-open");
    searchInput?.setAttribute("aria-expanded", "true");
    if (searchStatus) {
      searchStatus.textContent = (body.dataset.searchCount || "{count} search results").replace("{count}", String(matches.length));
    }
  }

  function moveSearchSelection(direction) {
    if (!searchResults?.classList.contains("is-open")) return;
    const links = Array.from(searchResults.querySelectorAll("a"));
    if (!links.length) return;
    activeResult = (activeResult + direction + links.length) % links.length;
    links.forEach((link, index) => {
      const active = index === activeResult;
      link.classList.toggle("is-active", active);
      link.setAttribute("aria-selected", String(active));
    });
    searchInput?.setAttribute("aria-activedescendant", links[activeResult].id);
    links[activeResult].scrollIntoView({ block: "nearest" });
  }

  function updateProgress() {
    if (!progress) return;
    const maximum = document.documentElement.scrollHeight - window.innerHeight;
    const ratio = maximum > 0 ? window.scrollY / maximum : 0;
    progress.style.width = `${Math.min(100, Math.max(0, ratio * 100))}%`;
  }

  function setActiveNavigation(slug) {
    if (!standalone) return;
    navigationLinks.forEach((link) => {
      if (link.dataset.navSlug === slug) link.setAttribute("aria-current", "location");
      else link.removeAttribute("aria-current");
    });
  }

  function updateScrollSpy() {
    scrollFrame = 0;
    if (!standalone || !trackedSections.length) return;
    const readingLine = Math.min(240, window.innerHeight * 0.3);
    let active = trackedSections[0];
    for (const section of trackedSections) {
      if (section.getBoundingClientRect().top <= readingLine) active = section;
      else break;
    }
    if (window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2) {
      active = trackedSections[trackedSections.length - 1];
    }
    setActiveNavigation(active.dataset.navSlug);
  }

  function scheduleViewportUpdate() {
    updateProgress();
    if (!scrollFrame) scrollFrame = window.requestAnimationFrame(updateScrollSpy);
  }

  function initializeScrollSpy() {
    if (!standalone || !trackedSections.length) return;
    const observer = new IntersectionObserver(scheduleViewportUpdate, {
      rootMargin: "-24% 0px -66% 0px",
      threshold: [0, 0.01, 1]
    });
    trackedSections.forEach((section) => observer.observe(section));
    navigationLinks.forEach((link) => {
      link.addEventListener("click", () => setActiveNavigation(link.dataset.navSlug));
    });
    updateScrollSpy();
  }

  function applyLabChoice(kind, choice, persistUrl) {
    if (!componentLab) return;
    componentLab.dataset[kind] = choice;
    const buttons = kind === "density" ? labDensityButtons : labWidthButtons;
    buttons.forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset[`lab${kind[0].toUpperCase()}${kind.slice(1)}`] === choice));
    });
    if (kind === "width") {
      componentLab.querySelectorAll("[data-lab-story]").forEach((story) => {
        story.hidden = story.dataset.width !== choice;
      });
    }
    if (persistUrl) {
      const url = new URL(window.location.href);
      url.searchParams.set(kind, choice);
      history.replaceState(null, "", url);
    }
  }

  function initializeComponentLab() {
    if (!componentLab) return;
    const params = new URLSearchParams(window.location.search);
    const density = ["compact", "standard"].includes(params.get("density")) ? params.get("density") : "standard";
    const width = ["standard", "long", "rtl"].includes(params.get("width")) ? params.get("width") : "standard";
    applyLabChoice("density", density, false);
    applyLabChoice("width", width, false);
    labDensityButtons.forEach((button) => button.addEventListener("click", () => applyLabChoice("density", button.dataset.labDensity, true)));
    labWidthButtons.forEach((button) => button.addEventListener("click", () => applyLabChoice("width", button.dataset.labWidth, true)));
  }

  async function loadSearchIndex() {
    if (searchIndex.length || standalone) return;
    try {
      const response = await fetch(`${root}assets/search-index-${locale}.json`);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      searchIndex = await response.json();
    } catch (error) {
      console.warn("Global search requires the generated site to be served over HTTP.", error);
    }
  }

  themeButtons.forEach((button) => {
    button.addEventListener("click", () => applyTheme(button.dataset.themeChoice, true));
  });

  languageButton?.addEventListener("click", () => {
    if (languageMenu?.hidden) openLanguageMenu();
    else closeLanguageMenu(false);
  });
  languageButton?.addEventListener("keydown", (event) => {
    if (event.key === "ArrowDown") {
      event.preventDefault();
      openLanguageMenu();
      languageMenu?.querySelector("a")?.focus();
    }
  });
  languageMenu?.addEventListener("keydown", (event) => {
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault();
      moveLanguageFocus(event.key === "ArrowDown" ? 1 : -1);
    } else if (event.key === "Escape") {
      event.preventDefault();
      closeLanguageMenu(true);
    }
  });
  languageMenu?.querySelectorAll("[data-locale-target]").forEach((link) => {
    link.addEventListener("click", (event) => {
      event.preventDefault();
      localStorage.setItem("qds-locale", link.dataset.localeTarget);
      const target = new URL(link.href, window.location.href);
      if (window.location.hash) target.hash = window.location.hash;
      window.location.assign(target.href);
    });
  });

  menuButton?.addEventListener("click", () => {
    if (body.classList.contains("nav-open")) closeNavigation(true);
    else openNavigation();
  });
  scrim?.addEventListener("click", () => closeNavigation(true));

  searchInput?.addEventListener("focus", async () => {
    await loadSearchIndex();
    if (searchInput.value) renderSearch(searchInput.value);
  });
  searchInput?.addEventListener("input", async (event) => {
    const value = event.currentTarget.value;
    await loadSearchIndex();
    renderSearch(value);
  });
  searchInput?.addEventListener("keydown", (event) => {
    if (event.key === "ArrowDown") {
      event.preventDefault();
      moveSearchSelection(1);
    } else if (event.key === "ArrowUp") {
      event.preventDefault();
      moveSearchSelection(-1);
    } else if (event.key === "Enter" && activeResult >= 0) {
      const active = searchResults?.querySelectorAll("a")[activeResult];
      if (active) window.location.href = active.href;
    } else if (event.key === "Escape") {
      closeSearch();
      searchInput.blur();
    }
  });

  document.addEventListener("pointerdown", (event) => {
    if (!searchResults?.contains(event.target) && event.target !== searchInput) closeSearch();
    if (!languageMenu?.contains(event.target) && !languageButton?.contains(event.target)) closeLanguageMenu(false);
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      if (languageMenu && !languageMenu.hidden) closeLanguageMenu(true);
      else if (body.classList.contains("nav-open")) closeNavigation(true);
      else closeSearch();
    }
    if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
      event.preventDefault();
      searchInput?.focus();
    }
    if (event.key === "/" && !event.metaKey && !event.ctrlKey && !event.altKey) {
      const target = event.target;
      const isEditing = target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement;
      if (!isEditing) {
        event.preventDefault();
        searchInput?.focus();
      }
    }
  });

  window.addEventListener("scroll", scheduleViewportUpdate, { passive: true });
  window.addEventListener("hashchange", scheduleViewportUpdate);
  window.addEventListener("resize", () => {
    if (window.innerWidth > 920) closeNavigation(false);
    synchronizeNavigationAvailability();
    scheduleViewportUpdate();
  });

  localStorage.setItem("qds-locale", locale);
  applyTheme(currentTheme(), false);
  synchronizeNavigationAvailability();
  initializeScrollSpy();
  initializeComponentLab();
  scheduleViewportUpdate();
})();
