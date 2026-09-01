# Brand and portfolio typography

This document defines the QenTerra brand, editorial, and portfolio type pairing. It is intentionally separate from the shared product-UI typography in `tokens/typography.json`.

## Pairing

| Role | Family | Recommended range |
| --- | --- | --- |
| Display and feature heading | Tektur | `400–900`, width `75–100` |
| Section heading | Onest | `600–800` |
| Navigation | Onest | `500–700` |
| Body and long-form reading | Onest | `400–500` |
| Metadata and captions | Onest | `400–600`, tabular numerals when values align |

Tektur gives the identity its engineered, constructed voice. Use it for short, high-impact text rather than long paragraphs. Onest carries the information layer: it stays calm, readable, and fully usable in Russian and English.

Do not silently apply this pairing to Cadence or other native application UI. Shared product interfaces continue to use platform system fonts unless a product-specific decision explicitly replaces them.

## Canonical assets

| Family | Design tools | Web | License |
| --- | --- | --- | --- |
| Tektur | `assets/typography/tektur/Tektur[wdth,wght].ttf` | `assets/typography/tektur/Tektur[wdth,wght].woff2` | `assets/typography/tektur/OFL.txt` |
| Onest | `assets/typography/onest/Onest[wght].ttf` | `assets/typography/onest/Onest[wght].woff2` | `assets/typography/onest/OFL.txt` |

The TTF files are the canonical source for Sketch and other design tools. The WOFF2 files are the canonical web delivery assets. Do not convert from an installed system copy: use these pinned files so collaborators and builds receive the same outlines and metadata.

Exact versions, axes, upstream revisions, release archives, byte counts, SHA-256 hashes, and acquisition URLs are recorded in `assets/typography/manifest.json`. Both families are licensed under SIL Open Font License 1.1, including commercial use subject to the license terms preserved beside each family.

## Web setup

```css
@font-face {
  font-family: "Tektur";
  src: url("/fonts/Tektur[wdth,wght].woff2") format("woff2-variations");
  font-style: normal;
  font-weight: 400 900;
  font-stretch: 75% 100%;
  font-display: swap;
}

@font-face {
  font-family: "Onest";
  src: url("/fonts/Onest[wght].woff2") format("woff2-variations");
  font-style: normal;
  font-weight: 100 900;
  font-display: swap;
}
```

Keep the public URL and bundler path product-specific. The Design System stores the canonical binaries; it does not publish them through the existing npm or Swift packages.

## Проверка и использование

Tektur используется для коротких display-заголовков и ключевых брендовых фраз. Onest используется для заголовков разделов, навигации, основного текста, блога, резюме и метаданных. Оба семейства поддерживают кириллицу и латиницу; Tektur также включает греческий набор.

Файлы TTF предназначены для Sketch и других дизайн-инструментов, WOFF2 — для будущего сайта. Оригинальные лицензии OFL лежат рядом со шрифтами. Системная типографика приложений при этом не меняется.

Run the focused integrity gate after any typography-asset change:

```sh
python3 scripts/verify_typography_assets.py
```

The validator checks the closed asset inventory, byte sizes, hashes, OFL text, SFNT family metadata, variable axes, version declarations, and representative Latin, Cyrillic, and Greek glyph coverage.
