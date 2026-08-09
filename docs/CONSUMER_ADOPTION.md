# Product adoption

The consumer doctor is a read-only migration aid, not an automatic compliance badge. Copy `templates/design/qds-consumer.json` and `qds-exceptions.json` into a product, replace every placeholder, then run:

```bash
python3 /path/to/design-system/scripts/audit_consumer.py /path/to/product --output /private/tmp/qds-product-report.json
```

The report checks declared local adapters, source-root boundaries, CSS hex colors, Swift numeric colors, SwiftUI corner radii and animation durations, plus narrowly documented exceptions. It never edits the product and refuses to write its report inside the consumer tree.

## Adoption order

1. Establish the manifest and record honest exceptions.
2. Connect the local Swift or CSS package.
3. Replace duplicated semantic values before product-specific geometry.
4. Migrate shared controls and states using Component Lab stories.
5. Run product-native build, accessibility, localization, and recovery checks.
6. Keep live/manual gaps explicit; a clean doctor report does not prove the rendered product.

## Result states

- `passed`: declared adapters were detected and covered static rules have no unexcepted findings.
- `failed`: schema, source boundary, adapter, or raw-value findings require action.
- exception: a narrow rule/path pair has a reason and review trigger; it is debt with paperwork, not magical absolution.
