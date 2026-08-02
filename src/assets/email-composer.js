(function () {
  "use strict";

  const root = document.querySelector("[data-email-composer]");
  if (!root || !window.QDSEmailRenderer) return;

  const parsePayload = (identifier) => JSON.parse(document.getElementById(identifier).textContent);
  const registry = parsePayload("qds-email-registry");
  const contactRegistry = parsePayload("qds-contact-channels");
  const labels = parsePayload("qds-email-labels");
  const pageLocale = document.documentElement.lang === "ru" ? "ru" : "en";
  const fieldMap = Object.fromEntries(registry.fields.map((field) => [field.id, field]));
  const channels = Object.fromEntries(contactRegistry.channels.map((channel) => [channel.id, channel.address]));
  const templateMap = Object.fromEntries(registry.templates.map((template) => [template.id, template]));

  const elements = {
    search: root.querySelector("[data-email-search]"),
    category: root.querySelector("[data-email-category]"),
    channel: root.querySelector("[data-email-channel]"),
    templateList: root.querySelector("[data-email-template-list]"),
    templateButtons: Array.from(root.querySelectorAll("[data-email-template]")),
    noResults: root.querySelector("[data-email-no-results]"),
    form: root.querySelector("[data-email-form]"),
    fields: root.querySelector("[data-email-fields]"),
    selectedCategory: root.querySelector("[data-email-selected-category]"),
    selectedTitle: root.querySelector("[data-email-selected-title]"),
    selectedSummary: root.querySelector("[data-email-selected-summary]"),
    preview: root.querySelector("[data-email-preview]"),
    previewFrame: root.querySelector("[data-email-preview-frame]"),
    previewEmpty: root.querySelector("[data-email-preview-empty]"),
    widthButtons: Array.from(root.querySelectorAll("[data-email-width]")),
    appearanceButtons: Array.from(root.querySelectorAll("[data-email-appearance]")),
    localeButtons: Array.from(root.querySelectorAll("[data-email-locale]")),
    copySubject: root.querySelector("[data-email-copy-subject]"),
    copyRich: root.querySelector("[data-email-copy-rich]"),
    copyText: root.querySelector("[data-email-copy-text]"),
    copyHtml: root.querySelector("[data-email-copy-html]"),
    reset: root.querySelector("[data-email-reset]"),
    fallback: root.querySelector("[data-email-fallback]"),
    fallbackValue: root.querySelector("[data-email-fallback-value]"),
    live: root.querySelector("[data-email-live]")
  };

  const state = {
    templateId: registry.templates[0].id,
    values: {},
    locale: pageLocale,
    width: "desktop",
    appearance: "light"
  };

  function normalized(value) {
    return String(value || "").toLocaleLowerCase(state.locale).trim();
  }

  function selectedTemplate() {
    return templateMap[state.templateId];
  }

  function announce(message) {
    elements.live.textContent = "";
    window.requestAnimationFrame(() => { elements.live.textContent = message; });
  }

  function filterTemplates() {
    const query = normalized(elements.search.value);
    const category = elements.category.value;
    const channel = elements.channel.value;
    let visible = 0;
    for (const button of elements.templateButtons) {
      const template = templateMap[button.dataset.emailTemplate];
      const copy = template.locales[state.locale];
      const matchesQuery = !query || normalized(`${copy.name} ${copy.summary} ${copy.subject}`).includes(query);
      const matchesCategory = !category || template.category === category;
      const matchesChannel = !channel || template.channel === channel;
      button.hidden = !(matchesQuery && matchesCategory && matchesChannel);
      if (!button.hidden) visible += 1;
    }
    elements.noResults.hidden = visible !== 0;
  }

  function fieldControl(reference) {
    const field = fieldMap[reference.id];
    const copy = field.locales[state.locale];
    const wrapper = document.createElement("div");
    wrapper.className = "email-field";
    const controlId = `email-field-${field.id}`;
    const helpId = `${controlId}-help`;
    const errorId = `${controlId}-error`;

    const label = document.createElement("label");
    label.htmlFor = controlId;
    label.innerHTML = `<span>${window.QDSEmailRenderer.escapeHtml(copy.label)}</span><small>${reference.required ? labels.required : labels.optional}</small>`;

    const control = field.type === "longText" ? document.createElement("textarea") : document.createElement("input");
    control.id = controlId;
    control.name = field.id;
    control.dataset.emailField = field.id;
    control.required = reference.required;
    control.maxLength = field.maxLength;
    control.placeholder = copy.example;
    control.autocomplete = "off";
    control.setAttribute("aria-describedby", `${helpId} ${errorId}`);
    if (field.type === "url") control.type = "url";
    else if (field.type === "boolean") control.type = "checkbox";
    else control.type = "text";
    if (["code", "url", "amount"].includes(field.type)) control.spellcheck = false;
    if (field.type === "code") control.inputMode = "numeric";
    if (field.type === "longText") control.rows = 4;
    if (state.values[field.id] !== undefined) {
      if (field.type === "boolean") control.checked = Boolean(state.values[field.id]);
      else control.value = state.values[field.id];
    }

    const help = document.createElement("p");
    help.id = helpId;
    help.className = "email-field-help";
    help.textContent = copy.help;
    const error = document.createElement("p");
    error.id = errorId;
    error.className = "email-field-error";
    error.dataset.emailError = field.id;
    error.hidden = true;

    control.addEventListener("input", () => {
      state.values[field.id] = field.type === "boolean" ? control.checked : control.value;
      control.removeAttribute("aria-invalid");
      error.hidden = true;
      updatePreview();
    });
    wrapper.append(label, control, help, error);
    return wrapper;
  }

  function renderForm() {
    const template = selectedTemplate();
    const copy = template.locales[state.locale];
    elements.selectedCategory.textContent = `${labels.categories[template.category]} · ${channels[template.channel]}`;
    elements.selectedTitle.textContent = copy.name;
    elements.selectedSummary.textContent = copy.summary;
    elements.fields.replaceChildren(...template.fields.map(fieldControl));
    elements.templateButtons.forEach((button) => {
      const selected = button.dataset.emailTemplate === template.id;
      button.setAttribute("aria-pressed", String(selected));
      if (selected) button.setAttribute("aria-current", "true");
      else button.removeAttribute("aria-current");
    });
    hideFallback();
    updatePreview();
  }

  function showErrors(errors) {
    const identifiers = new Set(errors.map((error) => error.split(":", 1)[0]));
    root.querySelectorAll("[data-email-error]").forEach((error) => {
      const visible = identifiers.has(error.dataset.emailError);
      error.hidden = !visible;
      error.textContent = visible ? labels.required_error : "";
      const control = root.querySelector(`[data-email-field="${error.dataset.emailError}"]`);
      if (visible) control?.setAttribute("aria-invalid", "true");
      else control?.removeAttribute("aria-invalid");
    });
  }

  function output(markErrors) {
    const rendered = window.QDSEmailRenderer.render(
      selectedTemplate(), fieldMap, state.values, state.locale, channels, state.appearance
    );
    if (markErrors) showErrors(rendered.errors);
    return rendered;
  }

  function updatePreview() {
    const rendered = output(false);
    elements.preview.dataset.width = state.width;
    if (!rendered.valid) {
      elements.previewFrame.hidden = true;
      elements.previewEmpty.hidden = false;
      elements.previewFrame.removeAttribute("srcdoc");
      return;
    }
    elements.previewEmpty.hidden = true;
    elements.previewFrame.hidden = false;
    elements.previewFrame.srcdoc = rendered.html;
  }

  function selectTemplate(identifier) {
    const nextTemplate = templateMap[identifier];
    if (!nextTemplate) return;
    const compatibleFields = new Set(nextTemplate.fields.map((reference) => reference.id));
    const retained = {};
    for (const [fieldId, value] of Object.entries(state.values)) {
      if (compatibleFields.has(fieldId) && fieldMap[fieldId].retainAcrossTemplates) retained[fieldId] = value;
    }
    state.templateId = identifier;
    state.values = retained;
    renderForm();
  }

  function renderTemplateListCopy() {
    for (const button of elements.templateButtons) {
      const copy = templateMap[button.dataset.emailTemplate].locales[state.locale];
      button.querySelector("strong").textContent = copy.name;
      button.querySelector("span").textContent = copy.summary;
    }
  }

  function hideFallback() {
    elements.fallback.hidden = true;
    elements.fallbackValue.value = "";
  }

  function showFallback(value) {
    elements.fallbackValue.value = value;
    elements.fallback.hidden = false;
    elements.fallbackValue.focus();
    elements.fallbackValue.select();
    announce(labels.copy_failed);
  }

  async function writeText(value) {
    if (!navigator.clipboard?.writeText) throw new Error("Clipboard API unavailable");
    await navigator.clipboard.writeText(value);
  }

  async function copy(kind) {
    const rendered = output(true);
    if (!rendered.valid) {
      root.querySelector('[aria-invalid="true"]')?.focus();
      return;
    }
    hideFallback();
    try {
      if (kind === "rich") {
        if (!navigator.clipboard?.write || typeof ClipboardItem === "undefined") throw new Error("Rich clipboard unavailable");
        const item = new ClipboardItem({
          "text/html": new Blob([rendered.html], { type: "text/html" }),
          "text/plain": new Blob([rendered.plainText], { type: "text/plain" })
        });
        await navigator.clipboard.write([item]);
      } else if (kind === "subject") await writeText(rendered.subject);
      else if (kind === "text") await writeText(rendered.plainText);
      else await writeText(rendered.html);
      announce(labels.copied);
    } catch (_error) {
      showFallback(kind === "subject" ? rendered.subject : kind === "html" ? rendered.html : rendered.plainText);
    }
  }

  elements.templateList.addEventListener("click", (event) => {
    const button = event.target.closest("[data-email-template]");
    if (button) selectTemplate(button.dataset.emailTemplate);
  });
  elements.search.addEventListener("input", filterTemplates);
  elements.category.addEventListener("change", filterTemplates);
  elements.channel.addEventListener("change", filterTemplates);
  elements.widthButtons.forEach((button) => button.addEventListener("click", () => {
    state.width = button.dataset.emailWidth;
    elements.widthButtons.forEach((candidate) => candidate.setAttribute("aria-pressed", String(candidate === button)));
    updatePreview();
  }));
  elements.appearanceButtons.forEach((button) => button.addEventListener("click", () => {
    state.appearance = button.dataset.emailAppearance;
    elements.appearanceButtons.forEach((candidate) => candidate.setAttribute("aria-pressed", String(candidate === button)));
    updatePreview();
  }));
  elements.localeButtons.forEach((button) => button.addEventListener("click", () => {
    state.locale = button.dataset.emailLocale;
    elements.localeButtons.forEach((candidate) => candidate.setAttribute("aria-pressed", String(candidate === button)));
    renderTemplateListCopy();
    filterTemplates();
    renderForm();
  }));
  elements.copySubject.addEventListener("click", () => copy("subject"));
  elements.copyRich.addEventListener("click", () => copy("rich"));
  elements.copyText.addEventListener("click", () => copy("text"));
  elements.copyHtml.addEventListener("click", () => copy("html"));
  elements.reset.addEventListener("click", () => {
    state.values = {};
    elements.form.reset();
    renderForm();
    announce(labels.cleared);
    elements.fields.querySelector("input, textarea")?.focus();
  });

  renderForm();
  filterTemplates();
  root.dataset.ready = "true";
})();
