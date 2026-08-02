# ADR-008: Human-operated email templates

Status: accepted  
Date: 2026-08-02

## Context

QenTerra needs consistent operational email across general correspondence and future products. Free-form replies drift in tone, structure, channel ownership, localization, and safety. A full sending platform would add credentials, personal data, delivery state, compliance, and infrastructure that are outside a design system and were not requested.

## Decision

Maintain one bilingual registry of 48 human-operated scenarios and a local stateless gallery/composer. The registry is the copy and variable source. A deterministic renderer produces email-safe HTML and semantically equivalent plain text. The person selects a scenario, enters verified facts, previews the result, copies it, reviews it in the destination email client, and sends it manually.

The system uses one QenTerra shell with an optional product name. General correspondence uses `contact@qenterra.com`; product support, accounts, operations, security, and payments use `support@qenterra.com`.

The data contract fixes four capabilities to `false`: sending email, persisting input, external requests, and marketing. Values are escaped, action links require absolute HTTPS, and output contains no scripts, forms, tracking, remote imagery, or full payment credentials. Only the public product name may survive a template switch in the current in-memory page state.

## Consequences

- People get fast, consistent, localized starting points without granting the design-system site access to mail or accounts.
- The same scenario can be consumed by future products without naming current applications.
- Copy, schema, renderer, UI, screenshots, and both master references must change together.
- Manual review remains mandatory. Copy success does not prove delivery, recipient correctness, or rendering in Apple Mail, Gmail, Outlook, or another client.
- Adding campaigns, newsletters, bulk recipients, tracking, sending, drafts, or account integration requires a separate product and a new explicit decision; it cannot be smuggled into this tool as a convenient little checkbox. That road has invoices and compliance lawyers at the end.
