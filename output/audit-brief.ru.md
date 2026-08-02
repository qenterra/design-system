# Cadence, Unspool и Lilt — аудит текущего UX/UI

Снимок доказательств: локальные репозитории на 2026-08-01.

- Cadence: `3d96b5a`; есть актуальные production-backed screenshots, но screenshot root обходит production tint.
- Unspool: `54b29f1`; текущий source новее опубликованных product screenshots.
- Lilt: `3d0ca81`; текущих rendered screenshots нет, а старый output показывает заменённые концепции.

Аудит объединяет current SwiftUI source, tokens, specifications, documentation, screenshots и независимый fresh-eyes review. Он не доказывает live native rendering, VoiceOver, network, audio, Telegram, permissions и real-device acceptance.

## Итоговый вердикт

Ни одно приложение по отдельности не является полным эталоном семьи.

- Cadence — самый сильный донор визуальной идентичности и композиции контента.
- Unspool — самый сильный донор операционных потоков и токен-дисциплины.
- Lilt — самый сильный донор states, motion, privacy и localization.

Утверждённое ядро: визуальная идентичность Cadence + дисциплина компонентов и workflows Unspool + архитектура states/motion/copy Lilt.

## Сравнительная оценка

| Область | Cadence | Unspool | Lilt |
| --- | ---: | ---: | ---: |
| Визуальная идентичность | 5 | 4 | 4 |
| Адаптивная тема | 5 | 5 | 1 |
| Дисциплина layout tokens | 2 | 5 | 2 |
| Типографика | 4 | 5 | 2 |
| Главный workflow | 4 | 5 | 4 |
| State и recovery | 4 | 5 | 5 |
| Motion | 2 | 4 | 5 |
| Microcopy | 3 | 4 | 5 |
| Локализация | 1 | 2 | 5 |
| Keyboard/accessibility | 3 | 4 | 3 |
| Актуальность docs | 3 | 2 | 2 |

Оценки — относительная сводка доказательств, а не абсолютный рейтинг.

## Межпродуктовые расхождения

### Тема

Cadence даёт adaptive custom Soft Graphite с System/Light/Dark. Unspool даёт adaptive system-semantic surfaces. Lilt жёстко принуждает Dark. Решение: сохранить узнаваемые graphite values Cadence, взять semantic/adaptive дисциплину Unspool и убрать forced appearance Lilt.

### Навигация

Cadence в коде стартует collapsed, хотя spec требует expanded на новой установке. Unspool стартует expanded вопреки compact rail. Lilt использует labeled Settings sidebar и не должен наследовать application rail. Решение: общие states и behavior, но не universal width/default.

### Типографика

Cadence имеет semantic system styles с local display exceptions. Unspool — лучшую compact role scale. Lilt — много local 10,5–11,5 pt и слабых metadata. Решение: shared semantic roles, system/dynamic mapping, без half-point и с явным minimum supporting text.

### Motion

Cadence имеет хорошие, но feature-local timings. Unspool централизует 80/100/150 ms. Lilt определяет semantic motion events и accessibility fallbacks. Решение: event architecture Lilt, restraint Unspool и measured product-specific continuous physical motion.

### Локализация и copy

В Cadence нет String Catalog и сотни literals. В Unspool catalog частичный. Lilt имеет полный catalog и почти не имеет direct UI strings. Решение: String Catalog или platform i18n обязателен вместе с typed/generated keys, plurals, locale formatting и specific recovery copy.

### Управление скриншотами

Cadence актуален по структуре, но идёт по неверному tint path. Unspool старее source. Lilt показывает старые concepts. Решение: каждому продукту нужна current privacy-safe fixture matrix по themes, widths, states и accessibility modes.

## Cadence

### Сильные стороны

- Сильная adaptive Soft Graphite palette и иерархия surfaces.
- Зрелые three-pane Library, Track Table, Now Playing, Queue и persistent player.
- Надёжный Scan → Review → Import → Complete/Recover.
- Native macOS controls, toolbar search, menus, sheets, popovers, shortcuts и Finder recovery.
- Skippable, repeatable и truthful Guide без автодействий с данными.

### Главные находки

- Smart Collections обещают `Save`, но не переживают relaunch: дефект доверия.
- Screenshot harness обходит production tint и показывает system blue.
- New install получает icon-only navigation; Library/Playlists делят символ.
- Shared row states есть, но screens вручную давят hover/focus.
- Radius, motion, typography exceptions и constraints разбросаны.
- UI strings hardcoded без String Catalog.
- Album/Artist менее playback-first, чем требует направление.
- Import Review может clipping на minimum width и требует live verification.

### Решение для семьи

Keep: palette, Library, tables, import review, player, Now Playing, queue, Guide, Trash recovery. Adapt: rail, Settings containers, buttons, row states, headers, search, state components, localization. Replace: non-durable promise, duplicate symbols, scattered values, hardcoded copy, manual state suppression, screenshot root. Product-specific: artwork haze, playback transport, audio path, lyrics, metadata, queue semantics.

## Unspool

### Сильные стороны

- Лучший сквозной поток: Chat → Range → Filters → Selection → Destination → Preflight → Download → Recovery.
- Count, size, destination, conflict policy и cancellation остаются видимыми.
- Плотная, сканируемая filename-first table.
- Safe default `Skip`, явные `Replace` и `Save a Copy`.
- Сильный lifecycle для scan, partial, offline, downloads, interruptions, history и export.
- Лучшая имеющаяся база spacing/radius/type/button/focus/motion tokens.
- Synthetic fixtures изолированы от реальных Telegram data.

### Главные находки

- Screenshots устарели.
- Expanded rail противоречит compact spec и съедает workspace.
- Critical category filters исчезают в безиндикаторном horizontal scroll.
- Setup показывает validation на untouched fields.
- Часть Settings toggles без accessible label.
- Interrupted session можно выбросить без confirmation.
- Typed issues сводятся обратно к global string banner.
- History failures не имеют consistent recovery.
- String Catalog и plural rules неполны.

### Решение для семьи

Keep: token discipline, file table, selection summary, preflight, conflicts, filename hierarchy, history, fixtures, Quick Look/Finder. Adapt: responsive rail, toolbar, buttons, Settings Row, issue placement, localization, semantic palette. Replace: invisible overflow, pristine errors, unnamed toggles, unconfirmed discard, global errors, stale screenshots. Product-specific: Telegram chats, ranges, sender filters, attachment taxonomy, filename contract, queue/conflicts.

## Lilt

### Сильные стороны

- Лучшее различение Ready, Recording, Transcribing, Inserted и Copied.
- Реальные RMS/peak signals без имитации partial capability.
- Лучшая semantic motion model с Reduced Motion fallback.
- Лучшая localization architecture и privacy microcopy.
- Сильные HUD, Quick History, keycaps, model lifecycle и diagnostics preview.
- Верная menu-bar utility model и local/offline framing.

### Блокеры и главные находки

- Menu-panel `Insert` обходит target-app preservation/restoration и может действовать не в том контексте.
- Trial Dictation не изолирован вопреки onboarding promise.
- Все главные surfaces принуждают Dark.
- Много малых half-point sizes и weak tertiary text.
- HUD сводит разные failures к `Lilt needs help` и `Configure`.
- Optional Accessibility показан как одно из трёх required onboarding actions.
- Некоторые cards выглядят clickable, но работает только nested button.
- Settings arrow navigation из docs отсутствует.
- Visual sources/specs устарели и противоречат.
- Icon Composer source не подключён к target/bundle.

### Решение для семьи

Keep: state vocabulary, motion, localization, privacy copy, HUD, Quick History, keycaps, real signals, diagnostics preview. Adapt: adaptive palette, type, Settings groups, buttons, onboarding, model cards, status colors. Replace: forced Dark, generic recovery, broken target restoration, fake trial, raw values, stale sources, unwired icons. Product-specific: recording red, signals, timer, hold/release, models, clipboard/insertion, menu-bar shell.

## Системные приоритеты

1. До visual migration исправить trust/context blockers: persistence language Cadence, insertion target и trial isolation Lilt.
2. Утвердить semantic tokens и generated adapters.
3. Централизовать mandatory interaction states.
4. Сделать appearance adaptive везде.
5. Стандартизировать issue scope и recovery.
6. Перенести все strings в localization sources.
7. Пересобрать current screenshot harnesses.
8. Мигрировать surfaces независимо проверяемыми slices.

## Явные live gaps

- Current Lilt render, multi-display placement, pointer interception, permissions, insertion, model lifecycle и VoiceOver.
- Current Unspool minimum/wide render, Telegram login/data/network/disk/conflicts и VoiceOver.
- Cadence production tint, minimum-width Import Review, drag/drop, playback/listening, routes и VoiceOver.
- Все продукты в live Reduced Motion, Reduced Transparency, Increased Contrast, long localization и keyboard-only end-to-end.
