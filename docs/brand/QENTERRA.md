# QenTerra Marks and Banners

## Canonical palette

The current vector master uses two fixed brand neutrals:

- mid graphite `#6A6A73`;
- soft white `#E8E8EC`.

These values describe the supplied marks. Interface surfaces still use semantic design-system tokens. Do not sample, approximate, or globally replace colors inside an approved export.

## Asset families

### Logos

- `logos/vector/QenTerra Logo.svg` is the only scalable master and is preferred for dark graphite surfaces, web, print, and derived exports.
- `logos/raster/` provides transparent 512, 1024, and 2048 pixel exports rendered from that master.
- The supplied `Dry` and `Wet` 1024 pixel treatments are separate approved raster deliveries; each also has an `on Graphite` version for an opaque contrast field.
- Do not invent `Filled`, `Outlined`, `Dark`, or `Light` variants. Select the supplied file by actual surface contrast and delivery requirement.

### Retired legacy banners

The legacy raster and vector banner families were retired in 4.0. Do not restore or reuse their `banners/` paths. Use the supplied platform publication assets only for their named destinations; they are deliberately fixed exports, not a new universal banner family.

### Platform publication assets

- `platforms/youtube/YouTube Channel Banner (2560x1440px).png` is the fixed YouTube channel-art export; keep its native canvas and safe area intact.
- `platforms/youtube/YouTube Watermark (150px).png` is the supplied video watermark, not a replacement for the primary logo.
- `platforms/buy-me-a-coffee/Buy Me a Coffee Banner (1600x400px).png` is the supplied support acknowledgement banner.
- These platform-specific deliveries do not replace the responsive banner or logo families and must not be cropped, recoloured, or repurposed for other channels.

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
- no mixing or reconstructing pieces from separate exports;
- no low-resolution raster when a vector or larger canonical export is available.

## Export choice

Use SVG when the consumer supports it safely. Use PNG for fixed raster pipelines, screenshots, stores, or platforms that require it. Choose the smallest raster that still renders at or above its native pixel size; never upscale a smaller logo to fake a larger master.

Every delivered file must already exist in [`../../assets/brand/manifest.json`](../../assets/brand/manifest.json). A derived export becomes canonical only after it is named, placed, manifested, reviewed on light and dark backgrounds, and documented here if it introduces a new role.

## Migrations

The `Dark/Light Logo` and `Filled/Outlined` paths were retired in 3.0. Replace scalable consumers with `logos/vector/QenTerra Logo.svg`. Use the transparent raster exports only at or below their native dimensions; use an approved `on Graphite` raster when the mark needs its own opaque contrast field on a light or busy surface.

The legacy `banners/` paths were retired in 4.0. Replace a named YouTube or Buy Me a Coffee placement with its documented asset under `platforms/`; otherwise use the logo family and a product-owned layout rather than reconstructing a legacy banner.

## Contact channels

- [`contact@qenterra.com`](mailto:contact@qenterra.com) is the general company and brand address for inquiries, partnerships, press, and business or legal correspondence.
- [`support@qenterra.com`](mailto:support@qenterra.com) is the product-help address for troubleshooting, bug reports, and accessibility support.

Neither address replaces a repository's private vulnerability-reporting route. Exact machine-readable roles live in [`../../registry/contact-channels.json`](../../registry/contact-channels.json); UI and repository copy must not swap or invent their purposes.
