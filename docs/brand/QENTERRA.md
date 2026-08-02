# QenTerra Marks and Banners

## Canonical palette

The vector masters use two fixed brand neutrals:

- dark graphite `#292929`;
- soft white `#E7E7E7`.

These values describe the supplied marks. Interface surfaces still use semantic design-system tokens. Do not sample, approximate, or globally replace colors inside an approved export.

## Asset families

### Logos

- `logos/vector/` is preferred for scalable UI, web, print, and derived exports.
- `logos/raster/` provides fixed 512, 1024, and 2048 pixel exports.
- `Filled` is the default when the mark must remain stable at small sizes.
- `Outlined` is for larger, quieter placements where the inner detail remains legible.
- `Dark` and `Light` describe the intended surrounding appearance. Select by rendered contrast, not filename superstition.

### Banners

- `banners/vector/` is preferred for responsive headers, documentation, and publication artwork.
- `banners/raster/` provides 1024, 2048, and 4096 pixel exports.
- Standard banners are the default family signature.
- Alternative banners are intentional variants, not automatic replacements for the standard form.

## Placement

- Preserve aspect ratio and internal geometry.
- Leave clear space around the complete visible mark. Use at least the height of the smallest primary symbol as a practical minimum when no layout-specific specification exists.
- Keep the complete mark inside the safe area. Do not crop lettering, outline, or terminal shapes to make a layout fit.
- Use one mark per visual region. Repeated logos do not become more branded; they become wallpaper with a legal department.
- On photography or illustration, provide a quiet contrast field rather than adding arbitrary shadows, strokes, or glows.

## Prohibited transformations

- no recoloring, gradients, opacity fades, textures, or blend-mode effects;
- no rotation, skew, stretch, perspective, or independent movement of parts;
- no reconstruction with live type or substituted glyphs;
- no extra border, container, badge, or slogan unless a documented composition requires it;
- no mixing filled and outlined parts from different exports;
- no low-resolution raster when a vector or larger canonical export is available.

## Export choice

Use SVG when the consumer supports it safely. Use PNG for fixed raster pipelines, screenshots, stores, or platforms that require it. Choose the smallest raster that still renders at or above its native pixel size; never upscale a smaller logo to fake a larger master.

Every delivered file must already exist in [`../../assets/brand/manifest.json`](../../assets/brand/manifest.json). A derived export becomes canonical only after it is named, placed, manifested, reviewed on light and dark backgrounds, and documented here if it introduces a new role.

## Contact channels

- [`contact@qenterra.com`](mailto:contact@qenterra.com) is the general company and brand address for inquiries, partnerships, press, and business or legal correspondence.
- [`support@qenterra.com`](mailto:support@qenterra.com) is the product-help address for troubleshooting, bug reports, and accessibility support.

Neither address replaces a repository's private vulnerability-reporting route. Exact machine-readable roles live in [`../../registry/contact-channels.json`](../../registry/contact-channels.json); UI and repository copy must not swap or invent their purposes.
