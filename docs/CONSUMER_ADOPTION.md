# Product adoption

The consumer doctor is a read-only migration aid, not an automatic compliance badge. Copy `templates/design/design-system-consumer.json` and `design-system-exceptions.json` into a product, replace every placeholder, then run:

```bash
python3 /path/to/design-system/scripts/audit_consumer.py /path/to/product --output /private/tmp/design-system-product-report.json
```

The report validates declared released packages and capabilities, source-root boundaries, CSS hex colors, Swift numeric colors, SwiftUI corner radii and animation durations, plus narrowly documented exceptions. It never edits the product and refuses to write its report inside the consumer tree.

## Adoption order

1. Establish the manifest and record honest exceptions.
2. Connect a versioned public npm or SwiftPM package; use a local package path only while changing Design System itself.
3. Replace duplicated semantic values before product-specific geometry.
4. Migrate shared controls and states from delivered registry contracts; do not treat specification-only entries as installable code.
5. Run product-native build, accessibility, localization, and recovery checks.
6. Keep live/manual gaps explicit; a clean doctor report does not prove the rendered product.

## Result states

- `passed`: declared adapters were detected and covered static rules have no unexcepted findings.
- `failed`: schema, source boundary, adapter, or raw-value findings require action.
- exception: a narrow rule/path pair has a reason and review trigger; it is debt with paperwork, not magical absolution.

## Package source and authentication

Production consumers pin an immutable SemVer release from
`https://github.com/qenterra/packages` or npm package
`@qenterra/design-tokens`. Both are public and require no read credential.
Local paths are for coordinated Design System work, not a silent production
dependency. A clean package install proves dependency and API availability
only. Product-native build, rendering, accessibility, permissions, persistence,
and recovery still require their own evidence.
