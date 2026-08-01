(function () {
  "use strict";

  const body = document.body;
  const root = body.dataset.root || "";
  const standalone = body.dataset.standalone === "true";
  const searchInput = document.querySelector("[data-search]");
  const searchResults = document.querySelector("[data-search-results]");
  const menuButton = document.querySelector("[data-menu-button]");
  const scrim = document.querySelector("[data-scrim]");
  const progress = document.querySelector("[data-progress]");
  const themeButtons = Array.from(document.querySelectorAll("[data-theme-choice]"));
  let searchIndex = window.QDS_SEARCH_INDEX || [];
  let activeResult = -1;
  let menuReturnTarget = null;

  function applyTheme(choice, persist) {
    if (choice === "system") {
      document.documentElement.removeAttribute("data-theme");
    } else {
      document.documentElement.dataset.theme = choice;
    }
    themeButtons.forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.themeChoice === choice));
    });
    if (persist) {
      localStorage.setItem("qds-theme", choice);
    }
  }

  function currentTheme() {
    return localStorage.getItem("qds-theme") || "system";
  }

  function openNavigation() {
    menuReturnTarget = document.activeElement;
    body.classList.add("nav-open");
    menuButton?.setAttribute("aria-expanded", "true");
    document.querySelector(".site-nav a")?.focus();
  }

  function closeNavigation(restoreFocus) {
    body.classList.remove("nav-open");
    menuButton?.setAttribute("aria-expanded", "false");
    if (restoreFocus && menuReturnTarget instanceof HTMLElement) {
      menuReturnTarget.focus();
    }
  }

  function normalized(value) {
    return value.toLocaleLowerCase().trim();
  }

  function closeSearch() {
    if (!searchResults) return;
    searchResults.classList.remove("is-open");
    searchResults.replaceChildren();
    activeResult = -1;
  }

  function resultUrl(item) {
    if (standalone) return `#section-${item.section}`;
    return `${root}${item.path}#section-${item.section}`;
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
        const haystack = normalized(`${item.title} ${item.page} ${item.text}`);
        const titleMatch = normalized(item.title).includes(value) ? 0 : 1;
        return { item, score: haystack.includes(value) ? titleMatch : 99 };
      })
      .filter((entry) => entry.score < 99)
      .sort((a, b) => a.score - b.score || a.item.section - b.item.section)
      .slice(0, 10);

    if (!matches.length) {
      const empty = document.createElement("p");
      empty.className = "search-empty";
      empty.textContent = "No matching section. Try a component, state, platform, or product name.";
      searchResults.append(empty);
    } else {
      matches.forEach(({ item }) => {
        const link = document.createElement("a");
        link.className = "search-result";
        link.href = resultUrl(item);
        const title = document.createElement("strong");
        title.textContent = item.title;
        const meta = document.createElement("span");
        meta.textContent = `${item.page} · Section ${item.section}`;
        link.append(title, meta);
        link.addEventListener("click", closeSearch);
        searchResults.append(link);
      });
    }
    searchResults.classList.add("is-open");
  }

  function moveSearchSelection(direction) {
    if (!searchResults?.classList.contains("is-open")) return;
    const links = Array.from(searchResults.querySelectorAll("a"));
    if (!links.length) return;
    activeResult = (activeResult + direction + links.length) % links.length;
    links.forEach((link, index) => link.classList.toggle("is-active", index === activeResult));
    links[activeResult].scrollIntoView({ block: "nearest" });
  }

  function updateProgress() {
    if (!progress) return;
    const maximum = document.documentElement.scrollHeight - window.innerHeight;
    const ratio = maximum > 0 ? window.scrollY / maximum : 0;
    progress.style.width = `${Math.min(100, Math.max(0, ratio * 100))}%`;
  }

  async function loadSearchIndex() {
    if (searchIndex.length || standalone) return;
    try {
      const response = await fetch(`${root}assets/search-index.json`);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      searchIndex = await response.json();
    } catch (error) {
      console.warn("Global search requires the generated site to be served over HTTP.", error);
    }
  }

  themeButtons.forEach((button) => {
    button.addEventListener("click", () => applyTheme(button.dataset.themeChoice, true));
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
    await loadSearchIndex();
    renderSearch(event.currentTarget.value);
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
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      if (body.classList.contains("nav-open")) closeNavigation(true);
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

  window.addEventListener("scroll", updateProgress, { passive: true });
  window.addEventListener("resize", () => {
    if (window.innerWidth > 920) closeNavigation(false);
  });

  applyTheme(currentTheme(), false);
  updateProgress();
})();
