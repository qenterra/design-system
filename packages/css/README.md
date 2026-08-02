# @qenterra/design-tokens

Private local CSS package generated from QenTerra Design System sources.

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
