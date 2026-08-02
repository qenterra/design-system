# QenTerra human-operated email system

This document defines how a person selects, fills, reviews, copies, and maintains QenTerra email templates. The tool is a local writing surface. It is not an email sender, CRM, campaign system, or source of product truth.

## Operating boundary

The Email page may read the committed template and contact registries, accept temporary input, render a preview, and copy an output. It must not:

- send or schedule email;
- access an email account, address book, inbox, or recipient list;
- save input, drafts, history, or clipboard content;
- make external requests or load remote assets;
- add telemetry, tracking pixels, link rewriting, open receipts, or analytics;
- support newsletters, campaigns, marketing, bulk delivery, or unsubscribe flows.

Reloading the page clears the working values. Switching templates retains only fields used by both scenarios, so a name or product does not need to be entered again when it still has the same meaning. Unrelated fields leave the active in-memory state. Clear fields removes every current value and preview.

## Channel ownership

| Address | Use | Do not use for |
|---|---|---|
| `contact@qenterra.com` | General enquiries, partnerships, press, routing, declines, and correspondence closure | Product troubleshooting, account or payment events |
| `support@qenterra.com` | Product support, accessibility reports, account/security events, operations, purchases, and refunds | General press or partnership correspondence |

The template registry stores a semantic `channel` identifier, not a duplicated address. `registry/contact-channels.json` resolves that identifier to the canonical address.

## Catalogue

The catalogue contains exactly 48 scenarios. Category counts are contractually validated:

| Category | Count | Scope |
|---|---:|---|
| Contact | 9 | Receipt, clarification, delay, routing, partnership, press, scope, decline, closure |
| Support | 16 | Intake, environment, reproduction, diagnostics, screenshots, permissions, known issues, workarounds, reproduction failure, fixes, resolution, inactivity, accessibility, unsupported cases |
| Account | 12 | Welcome, verification, sign-in, password and email changes, suspicious events, locks, deletion |
| Operation | 8 | Complete, partial, failed, exports, expiry, processing, invitations, access changes |
| Payment | 3 | Purchase confirmation, payment failure, refund |

Use the narrowest accurate scenario. Do not turn a nearby template into a different promise by rewriting half of it. If a recurring case has a distinct consequence or action, add and validate a real scenario.

## Message anatomy

Every localized scenario defines:

1. a human-readable name and usage summary;
2. a specific subject and hidden preheader;
3. an eyebrow and one message title;
4. one canonical greeting followed by short paragraphs containing verified facts without restating the title;
5. optional structured details;
6. at most one contextual callout;
7. at most one primary action with a visible fallback URL;
8. a QenTerra closing, responsible address, and receipt explanation;
9. semantically equivalent rich HTML and plain text.

The shell is intentionally restrained: 600 px maximum width, system fonts, one card, opaque surfaces, clear hierarchy, inline styles, table layout, and Light/Dark palettes. Product branding may appear as text through `productName`; product-specific logos, remote images, decorative banners, and campaign chrome do not belong here.

## Writing rules

- State what happened, what is known, what remains, and what the recipient can do.
- Separate confirmed facts from a request, estimate, or suspicion.
- Never claim that an issue is fixed, payment succeeded, refund arrived, account changed, deletion completed, or compromise occurred unless the source system confirms it.
- Avoid marketing claims, fake urgency, blame, cheerleading, apology padding, internal implementation terms, and vague `Something went wrong` language.
- Use calm direct sentences. One paragraph should normally do one job.
- Name dates, time zones, amounts, versions, references, permissions, and consequences precisely.
- Do not request passwords, recovery secrets, one-time codes, full card numbers, or unnecessary diagnostics by email.
- A security warning explains the safe action without declaring a breach from weak evidence.
- A payment message never includes full payment-card data.

## Localization contract

English and Russian must express the same event, certainty, action, warning, deadline, and recovery path. Natural localized syntax takes priority over literal word order. Variable identifiers, required/optional status, block conditions, channel, risk, and CTA presence remain structurally identical.

Do not translate product names, codes, references, URLs, or user-provided values. Format dates, amounts, and lists before entering them; the composer does not guess locale or currency from raw values.

## Field contract and privacy

Global fields live once in `registry/email-templates.json`. Each field has a stable identifier, data type, privacy class, maximum length, retention policy, and bilingual label/help/example. A template references fields and marks each one required or optional.

- `public`: reusable non-personal context, currently only the product name.
- `personal`: names, topics, and communication checkpoints.
- `sensitive`: support, operation, access, environment, and internal-reference context.
- `security`: action links, one-time codes, and expiry.
- `financial`: amounts, payment references, and timing.

Required means the output would otherwise be ambiguous, unsafe, or factually incomplete. Optional fields use conditional blocks and disappear cleanly when empty. Never substitute invented filler just to satisfy validation.

URLs must be absolute HTTPS URLs. The renderer rejects other schemes and escapes all entered values before placing them in HTML. Maximum lengths are safety and usability limits, not targets.

## Human workflow

1. Open the local Email page; the reference-site language controls only its interface.
2. Choose the email language independently, then search or filter by category and responsible channel.
3. Read the scenario summary; select the narrowest truthful template.
4. Fill fields from verified product, support, account, operation, or payment state.
5. Inspect both desktop/mobile width and Light/Dark preview where relevant.
6. Resolve every required-field error. Leave optional facts empty when unknown.
7. Copy the subject separately, then copy rich content for a capable client or plain text for a constrained one. HTML source is for diagnostics and integration work.
8. In the destination email client, verify From, To, Cc/Bcc, subject, names, product, dates, time zone, reference, amount/currency, claims, link label and destination, footer address, and line wrapping.
9. Send manually only after that review. The design system never reports the message as sent.
10. Close or reload the local page to discard working values.

If rich clipboard access fails, the page exposes a selected fallback value for manual copying. That fallback is deliberate; clipboard APIs are fickle little bureaucrats, especially outside a secure local origin.

## Output safety

The renderer produces a complete HTML document and plain text. HTML uses escaped values, presentation tables, inline CSS, a system-font stack, explicit colors, and visible fallback URLs. It contains no JavaScript, forms, attachments, CSS variables, external fonts, remote images, tracking, or hidden operational claims.

Light and Dark email appearances are explicit deterministic outputs. Each declares only its selected color scheme and uses a complete inline palette; it never partially recolors itself from the operating-system preference. Email clients vary, so compatibility still requires real-client QA.

## Adding or changing a template

1. Confirm that an existing scenario cannot represent the event without changing its consequence.
2. Choose category, channel, risk, and whether a warm illustration would ever be allowed. The current renderer intentionally ships no illustration.
3. Reuse existing fields. Add a field only for a distinct reusable semantic value and classify its privacy conservatively.
4. Author English and Russian together with identical variables and conditional structure.
5. Keep one CTA maximum; give it a safe label, absolute HTTPS variable, and visible fallback instruction.
6. Add or update focused schema/semantic tests, renderer tests, browser behavior assertions, and representative screenshots.
7. Update both master references, both email guides, changelog, version, generated outputs, and Obsidian routing when the contract changes.
8. Run the complete project verification and inspect representative real-client output before release.

## QA matrix

Automated gates must prove schema validity, exact scenario/category counts, locale and variable parity, channel ownership, prohibited capabilities, URL validation, escaping, optional-block removal, one-CTA maximum, plain/rich output, deterministic generation, syntax, link integrity, browser filtering, in-memory retention rules, clipboard fallback, and exact visual regression.

Human QA must cover English/Russian, Light/Dark, desktop/mobile, long values, empty optional fields, a routine contact message, a support message, a security action, an operation result, and a payment message. Test pasting into the supported versions of Apple Mail, Gmail, Outlook, and any other declared client. Check received rendering, not only the compose window.

Never claim delivery, spam placement, accessibility in a mail client, or cross-client compatibility from local screenshots alone.
