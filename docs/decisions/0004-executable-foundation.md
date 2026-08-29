# 0004: Executable foundation contracts

- Status: accepted
- Date: 2026-08-02

## Context

The first system releases documented a coherent family language, but broad token schemas, string-only semantic Swift names, and non-exact screenshot evidence still allowed drift to survive until product integration.

## Decision

- Give every token family a focused, fail-closed schema validated with the Python standard library.
- Reject unknown top-level fields, broken or cyclic references, incompatible component metric references, and undocumented raw metrics.
- Preserve the existing Swift facade while adding typed color, typography, motion, and component APIs.
- Export component metrics in CSS and keep reusable recipes opt-in.
- Treat `evidence/screenshots.json` as the exact visual matrix; current renders are temporary and compared pixel-for-pixel with committed baselines.
- Keep company and support addresses in a typed semantic registry so documentation and future products cannot swap their roles.

## Consequences

Token and registry changes fail earlier and require explicit exceptions. Consumers gain stable local APIs without package publication. Intentional visual changes require an explicit baseline update and review; static browser evidence still does not prove native rendering or assistive-technology behavior.
