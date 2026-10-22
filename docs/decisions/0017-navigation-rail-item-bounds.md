# Navigation rail item bounds for consumer overlays

- Status: accepted
- Date: 2026-10-22
- Owners: @qenterra

## Context

Profiled navigation rails must scroll at short heights while consumers retain ownership of destination reordering. Overlay positions calculated from fixed row indices become incorrect as the shared rail scrolls.

## Decision

Publish each destination and footer button's actual bounds through `NavigationRailItemBoundsKey<ID>`. Consumers resolve its `Anchor<CGRect>` values with the geometry proxy of their own overlay. The rail owns scrolling and native focus; the consumer owns reorder interaction and mutations.

## Alternatives

- Fixed row offsets require the consumer to duplicate shared padding, expansion, and scroll geometry.
- A consumer-local rail fork duplicates a reusable component and separates fixes from package delivery.

## Consequences

The preference key is an additive public API delivered in 1.1.0. Existing initializers and selection behavior remain compatible. Item identities must be unique across destinations and footer items. Preferences describe content bounds; consumers remain responsible for clipping and hit testing overlays to the visible rail viewport. No migration is required for consumers that do not add overlays.

## Verification

Native compact and expanded rail tests resolve the same item anchors before and after scrolling, including a footer initially below the viewport. Existing locked snapshots are compared without recording new baselines. Clean core-only and media consumers verify package delivery.

## Review trigger

Revisit when a rail adds sections, sticky rows, another scroll axis, or a different overlay ownership model.
