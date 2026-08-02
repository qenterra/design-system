(function (root, factory) {
  "use strict";
  const api = factory();
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  if (root) root.QDSEmailRenderer = api;
})(typeof window !== "undefined" ? window : globalThis, function () {
  "use strict";

  const VARIABLE = /\{\{([a-z][a-zA-Z0-9]*)\}\}/g;
  const CONTROL_CHARACTERS = /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/;

  function escapeHtml(value) {
    return String(value).replace(/[&<>"']/g, (character) => ({
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#39;"
    })[character]);
  }

  function variablesIn(value) {
    const variables = [];
    String(value).replace(VARIABLE, (_match, identifier) => {
      variables.push(identifier);
      return _match;
    });
    return variables;
  }

  function safeHttpsUrl(value) {
    let parsed;
    try {
      parsed = new URL(String(value));
    } catch (_error) {
      throw new Error("Use an absolute HTTPS URL.");
    }
    if (parsed.protocol !== "https:" || !parsed.hostname) {
      throw new Error("Use an absolute HTTPS URL.");
    }
    return parsed.href;
  }

  function validate(template, fieldMap, values) {
    const errors = [];
    for (const reference of template.fields) {
      const field = fieldMap[reference.id];
      const raw = values[reference.id];
      const empty = raw === undefined || raw === null || String(raw).trim() === "";
      if (reference.required && empty) {
        errors.push(`${reference.id}: This field is required.`);
        continue;
      }
      if (empty) continue;
      const value = String(raw);
      if (CONTROL_CHARACTERS.test(value)) {
        errors.push(`${reference.id}: Remove control characters.`);
      }
      if (value.length > field.maxLength) {
        errors.push(`${reference.id}: Use ${field.maxLength} characters or fewer.`);
      }
      if (field.type === "url") {
        try {
          safeHttpsUrl(value);
        } catch (error) {
          errors.push(`${reference.id}: ${error.message}`);
        }
      }
    }
    return { valid: errors.length === 0, errors };
  }

  function replaceVariables(value, values, html) {
    return String(value).replace(VARIABLE, (_match, identifier) => {
      const replacement = values[identifier] ?? "";
      return html ? escapeHtml(replacement) : String(replacement);
    });
  }

  function hasValues(value, values) {
    const variables = variablesIn(value);
    return variables.every((identifier) => {
      const candidate = values[identifier];
      return candidate !== undefined && candidate !== null && String(candidate).trim() !== "";
    });
  }

  function activeBlocks(items, values) {
    return (items || []).filter((item) => {
      if (item.condition && !String(values[item.condition] ?? "").trim()) return false;
      const source = [item.text, item.label, item.value, item.title].filter(Boolean).join(" ");
      return hasValues(source, values);
    });
  }

  function paletteFor(appearance) {
    if (appearance === "dark") {
      return {
        outer: "#0f0f11",
        card: "#18181b",
        secondary: "#232327",
        text: "#ffffff",
        muted: "#b8b8bf",
        border: "#3a3a40",
        action: "#ffffff",
        actionText: "#0f0f11"
      };
    }
    return {
      outer: "#f4f4f5",
      card: "#ffffff",
      secondary: "#f0f0f2",
      text: "#18181b",
      muted: "#5d5d66",
      border: "#dddde1",
      action: "#18181b",
      actionText: "#ffffff"
    };
  }

  function calloutPalette(tone, appearance) {
    const dark = appearance === "dark";
    return {
      neutral: dark ? ["#232327", "#ffffff"] : ["#f0f0f2", "#18181b"],
      success: dark ? ["#173b2b", "#d8ffe9"] : ["#e8f7ee", "#174d2f"],
      warning: dark ? ["#49351a", "#ffe7bc"] : ["#fff4df", "#6a4300"],
      destructive: dark ? ["#4a2225", "#ffdadd"] : ["#fdebec", "#7d2028"]
    }[tone] || (dark ? ["#232327", "#ffffff"] : ["#f0f0f2", "#18181b"]);
  }

  function render(template, fieldMap, values, locale, channels, appearance = "light") {
    const checked = validate(template, fieldMap, values);
    if (!checked.valid) {
      return { valid: false, errors: checked.errors, subject: "", preheader: "", html: "", plainText: "" };
    }

    const copy = template.locales[locale];
    const palette = paletteFor(appearance);
    const subject = replaceVariables(copy.subject, values, false);
    const preheader = replaceVariables(copy.preheader, values, false);
    const paragraphs = activeBlocks(copy.paragraphs, values);
    const details = activeBlocks(copy.details, values);
    const callout = copy.callout && activeBlocks([copy.callout], values).length ? copy.callout : null;
    const cta = copy.cta && hasValues(copy.cta.url, values) ? copy.cta : null;
    const channelAddress = channels[template.channel];

    const paragraphHtml = paragraphs.map((item) => (
      `<p style="margin:0 0 16px;color:${palette.text};font:400 16px/24px -apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;">${replaceVariables(item.text, values, true)}</p>`
    )).join("");

    const detailRows = details.map((item) => (
      `<tr><td style="padding:10px 12px;color:${palette.muted};font:600 12px/18px -apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;vertical-align:top;">${replaceVariables(item.label, values, true)}</td>` +
      `<td style="padding:10px 12px;color:${palette.text};font:400 14px/20px -apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;vertical-align:top;word-break:break-word;">${replaceVariables(item.value, values, true)}</td></tr>`
    )).join("");
    const detailsHtml = detailRows ? `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:8px 0 20px;border:1px solid ${palette.border};border-radius:10px;border-collapse:separate;overflow:hidden;">${detailRows}</table>` : "";

    let calloutHtml = "";
    if (callout) {
      const [background, text] = calloutPalette(callout.tone, appearance);
      calloutHtml = `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:8px 0 20px;background:${background};border-radius:10px;"><tr><td style="padding:16px;color:${text};font:400 14px/20px -apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;"><strong style="display:block;margin-bottom:4px;font-weight:700;">${replaceVariables(callout.title, values, true)}</strong>${replaceVariables(callout.text, values, true)}</td></tr></table>`;
    }

    let ctaHtml = "";
    let actionUrl = "";
    if (cta) {
      actionUrl = safeHttpsUrl(replaceVariables(cta.url, values, false));
      const safeUrl = escapeHtml(actionUrl);
      ctaHtml = `<table role="presentation" cellpadding="0" cellspacing="0" style="margin:8px 0 20px;"><tr><td style="border-radius:9px;background:${palette.action};"><a data-email-primary-action href="${safeUrl}" style="display:inline-block;padding:12px 18px;color:${palette.actionText};font:700 15px/20px -apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;text-decoration:none;border-radius:9px;">${replaceVariables(cta.label, values, true)}</a></td></tr></table>` +
        `<p style="margin:0 0 20px;color:${palette.muted};font:400 12px/18px -apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;word-break:break-all;">${replaceVariables(cta.fallback, values, true)}<br><a href="${safeUrl}" style="color:${palette.text};">${safeUrl}</a></p>`;
    }

    const html = `<!doctype html><html lang="${locale}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="color-scheme" content="light dark"><meta name="supported-color-schemes" content="light dark"><title>${escapeHtml(subject)}</title><style>@media (prefers-color-scheme:dark){.qds-email-outer{background:#0f0f11!important}.qds-email-card{background:#18181b!important}}</style></head>` +
      `<body style="margin:0;padding:0;background:${palette.outer};"><div style="display:none;max-height:0;overflow:hidden;opacity:0;color:transparent;">${escapeHtml(preheader)}</div>` +
      `<table class="qds-email-outer" role="presentation" width="100%" cellpadding="0" cellspacing="0" style="width:100%;background:${palette.outer};"><tr><td align="center" style="padding:28px 12px;">` +
      `<table class="qds-email-card" role="presentation" width="100%" cellpadding="0" cellspacing="0" style="width:100%;max-width:600px;background:${palette.card};border:1px solid ${palette.border};border-radius:14px;border-collapse:separate;overflow:hidden;"><tr><td style="padding:24px 28px 10px;color:${palette.text};font:750 20px/24px -apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;">QenTerra</td></tr>` +
      `<tr><td style="padding:18px 28px 8px;color:${palette.muted};font:700 11px/16px -apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;letter-spacing:.08em;text-transform:uppercase;">${replaceVariables(copy.eyebrow, values, true)}</td></tr>` +
      `<tr><td style="padding:0 28px 14px;color:${palette.text};font:750 28px/34px -apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;">${replaceVariables(copy.title, values, true)}</td></tr>` +
      `<tr><td style="padding:0 28px 8px;">${paragraphHtml}${detailsHtml}${calloutHtml}${ctaHtml}</td></tr>` +
      `<tr><td style="padding:18px 28px;border-top:1px solid ${palette.border};background:${palette.secondary};color:${palette.muted};font:400 12px/18px -apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;"><strong style="display:block;color:${palette.text};margin-bottom:4px;">${replaceVariables(copy.closing, values, true)}</strong><a href="mailto:${escapeHtml(channelAddress)}" style="color:${palette.text};">${escapeHtml(channelAddress)}</a><br><span>${replaceVariables(copy.receipt, values, true)}</span></td></tr></table>` +
      `</td></tr></table></body></html>`;

    const plainParts = [
      replaceVariables(copy.title, values, false),
      "",
      ...paragraphs.map((item) => replaceVariables(item.text, values, false)),
    ];
    if (details.length) {
      plainParts.push("", ...details.map((item) => `${replaceVariables(item.label, values, false)}: ${replaceVariables(item.value, values, false)}`));
    }
    if (callout) {
      plainParts.push("", replaceVariables(callout.title, values, false), replaceVariables(callout.text, values, false));
    }
    if (cta) {
      plainParts.push("", replaceVariables(cta.label, values, false), actionUrl);
    }
    plainParts.push("", replaceVariables(copy.closing, values, false), channelAddress, "", replaceVariables(copy.receipt, values, false));
    const plainText = plainParts.join("\n").replace(/\n{3,}/g, "\n\n").trim();

    return { valid: true, errors: [], subject, preheader, html, plainText };
  }

  return Object.freeze({ escapeHtml, safeHttpsUrl, validate, render });
});
