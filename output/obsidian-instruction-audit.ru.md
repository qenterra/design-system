# Аудит Obsidian-инструкций приложений и расширений

Область: 19 текущих файлов, чьи имена начинаются с Cadence, Lilt, Unspool, Browser extensions или Repository. Исходная база: 1 034 строки и 86 915 Unicode-символов.

## Вердикт

Корпус велик, но не бессмысленно дублирован на уровне файлов. У каждого сохранённого файла свой trigger: домен продукта, publication layer, этап browser-extension engineering или exceptional history reconstruction. Удаление ради красивого счётчика смешало бы safety boundaries и заставило агентов читать больше лишнего.

Настоящая проблема была в source ownership. Общие design facts транзитивно шли через Cadence, поэтому Lilt и Unspool могли наследовать устаревшую продуктовую трактовку. Точные palette/timing values также дублировались в Cadence prose до появления machine-readable source.

## Исправленные дефекты

- Добавлена одна canonical routing instruction для UX/UI app/site/extension.
- Наследование Lilt от Cadence заменено на explicit Lilt profile.
- Cross-product lookup Unspool заменён на его canonical profile.
- Из Cadence visual instruction убраны duplicated palette/motion values; product geometry осталась local.
- Browser-extension UI привязан к web/extension adapters.
- Public-document structure отделена от visual/interface ownership.
- Screenshot instructions привязаны к canonical matrix.
- Добавлены component и product-profile templates без копии token values.
- Добавлен read-only validator с negative tests на missing files, version drift и missing references.
- Обновлены Obsidian routing и README.

## Намеренно сохранено

### Доменные файлы Cadence

Albums, Artists, Now Playing/Queue/Lyrics, Tags/Smart Collections, library visual hierarchy и main development map остались раздельными: они задают разные product contracts и verification gates. Product geometry, playback, artwork и navigation semantics не принадлежат foundation.

### Development maps Lilt и Unspool

Оба сохраняют privacy, runtime, platform, storage и live-acceptance rules. В семейную систему переехала только shared visual ownership.

### Реконструкция истории Unspool

Инструкция близка к line limit, но имеет узкий destructive/history trigger и не может быть смешана с normal development. Её historical commit vocabulary не является design source.

### Browser-extension files

Architecture, UI/motion, localization, Pages/screenshots и release audit остались separate phases с разными failure modes. Family platform layer даёт semantics; extension files сохраняют host isolation, viewport, manifest, packaging и browser boundaries.

### Repository files

Public tree, legal/privacy, Wiki, screenshots и family documentation остаются отдельно от product UI. `repository-documentation-standard` владеет publication structure; `qenterra-design-system` — interface grammar и visual evidence.

## Результат удаления

Ни одна инструкция не удалена: не найдено orphaned или действительно redundant процесса. Убраны duplicated changing values и ambiguous cross-product inheritance.

## Новый canonical read order

1. Obsidian root `AGENTS.md` и `_agents/index.md`.
2. `Дизайн-система QenTerra — применение и развитие.md` для UX/UI.
3. Design-system `AGENTS.md`, `docs/MASTER.md`, platform layer и product profile.
4. Product-specific Obsidian instruction.
5. Current repository source, tests, specs и rendered evidence.

## Граница проверки

Аудит проверяет static routing, token/version ownership, templates и validator behavior. Он не доказывает live Obsidian rendering или production migration трёх приложений.
