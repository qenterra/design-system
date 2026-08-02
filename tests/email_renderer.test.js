"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const renderer = require(path.join(root, "src/assets/email-renderer.js"));
const registry = JSON.parse(fs.readFileSync(path.join(root, "registry/email-templates.json"), "utf8"));
const contactRegistry = JSON.parse(fs.readFileSync(path.join(root, "registry/contact-channels.json"), "utf8"));
const channels = Object.fromEntries(contactRegistry.channels.map((channel) => [channel.id, channel.address]));
const fieldMap = Object.fromEntries(registry.fields.map((field) => [field.id, field]));

function valuesFor(template, locale) {
  return Object.fromEntries(template.fields.map((reference) => [
    reference.id,
    fieldMap[reference.id].locales[locale].example
  ]));
}

function assertSafeOutput(output, template, locale) {
  assert.equal(output.valid, true, `${template.id}/${locale}: ${output.errors.join(" | ")}`);
  assert.ok(output.subject.length > 3);
  assert.ok(output.preheader.length > 3);
  assert.ok(output.plainText.includes(channels[template.channel]));
  assert.match(output.html, /role="presentation"/);
  assert.match(output.html, /max-width:600px/);
  assert.doesNotMatch(output.html, /var\(--/);
  assert.doesNotMatch(output.html, /<script|<form|<img/i);
  assert.doesNotMatch(output.html, /\{\{[a-z]/);
  assert.doesNotMatch(output.plainText, /\{\{[a-z]/);
  const primaryActions = (output.html.match(/data-email-primary-action/g) || []).length;
  assert.ok(primaryActions <= 1, `${template.id}/${locale}: more than one primary action`);
}

for (const template of registry.templates) {
  for (const locale of ["en", "ru"]) {
    const output = renderer.render(template, fieldMap, valuesFor(template, locale), locale, channels, "light");
    assertSafeOutput(output, template, locale);
    const dark = renderer.render(template, fieldMap, valuesFor(template, locale), locale, channels, "dark");
    assertSafeOutput(dark, template, locale);
  }
}

const verifyTemplate = registry.templates.find((template) => template.id === "account-verify-email");
const unsafeValues = valuesFor(verifyTemplate, "en");
unsafeValues.actionUrl = "javascript:alert(1)";
unsafeValues.recipientName = '<script>alert("x")</script>';
const unsafe = renderer.render(verifyTemplate, fieldMap, unsafeValues, "en", channels, "light");
assert.equal(unsafe.valid, false);
assert.match(unsafe.errors.join(" "), /HTTPS/);
assert.doesNotMatch(unsafe.html, /<script>/i);

const escapedValues = valuesFor(verifyTemplate, "en");
escapedValues.recipientName = '<script>alert("x")</script>';
const escaped = renderer.render(verifyTemplate, fieldMap, escapedValues, "en", channels, "light");
assert.equal(escaped.valid, true);
assert.match(escaped.html, /&lt;script&gt;/);
assert.doesNotMatch(escaped.html, /<script>alert/);

const missingValues = valuesFor(verifyTemplate, "en");
delete missingValues.recipientName;
const missing = renderer.render(verifyTemplate, fieldMap, missingValues, "en", channels, "light");
assert.equal(missing.valid, false);
assert.match(missing.errors.join(" "), /recipientName/);

const optionalTemplate = JSON.parse(JSON.stringify(registry.templates.find((template) => template.id === "operation-completed")));
optionalTemplate.fields.find((reference) => reference.id === "completedSummary").required = false;
const optionalValues = valuesFor(optionalTemplate, "en");
delete optionalValues.completedSummary;
const optional = renderer.render(optionalTemplate, fieldMap, optionalValues, "en", channels, "light");
assert.equal(optional.valid, true);
assert.doesNotMatch(optional.html, /Completed result/);

console.log(`Email renderer passed ${registry.templates.length * 2} localized templates plus hostile and optional cases.`);
