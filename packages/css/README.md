# @qenterra/design-tokens

Private CSS, JSON, icon, and component-recipe adapters generated from the
QenTerra Design System. The canonical sources remain in the private
`qenterra/design-system` repository; files in this package are build outputs.

## Install from GitHub Packages

Route only the QenTerra scope to GitHub Packages:

```ini
@qenterra:registry=https://npm.pkg.github.com
```

Authenticate with a read-only token supplied through the environment, never
committed to `.npmrc`:

```ini
//npm.pkg.github.com/:_authToken=${NODE_AUTH_TOKEN}
```

Then install an immutable version:

```sh
npm install @qenterra/design-tokens@2.0.0
```

Authorized GitHub Actions consumers should use a token with `packages: read`.
Local development can instead use `"@qenterra/design-tokens": "file:../design-system/packages/css"`.

## Exports

Reference it from a local web project and import the exported stylesheet:

```css
@import "@qenterra/design-tokens";
```

JavaScript tooling may import `@qenterra/design-tokens/tokens.json`. Change `tokens/*.json`, then run `python3 scripts/build.py`; do not edit `tokens.css` or `tokens.json` directly.

Semantic icon metadata is available from `@qenterra/design-tokens/icons.json`; render the platform-native symbol when one exists, or use the reviewed SVG fragment with the registry meaning intact.

Reusable component recipes are opt-in so product shells can remain native and distinct:

```css
@import "@qenterra/design-tokens/recipes.css";
```

The package also exports `tokens.css`, `tokens.json`, and `icons.json`
explicitly. This proprietary package may be consumed only by repositories and
products authorized by QenTerra; redistribution requires owner approval.
