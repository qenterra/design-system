# Аудит Obsidian-инструкций приложений и расширений

Область: 19 текущих файлов, чьи имена начинаются с Cadence, Lilt, Unspool, Browser extensions или Repository. Исходная база: 1 034 строки и 86 915 Unicode-символов.

## Вердикт

Корпус велик, но не бессмысленно дублирован на уровне файлов. У каждого сохранённого файла свой trigger: домен продукта, publication layer, этап browser-extension engineering или exceptional history reconstruction. Удаление ради красивого счётчика смешало бы safety boundaries и заставило агентов читать больше лишнего.

Проблема source ownership теперь закрыта и для interface design, и для repository documentation. Общие правила ведут в один canonical repository; продуктовые инструкции сохраняют только факты продукта и границы live verification.

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
- Repository, legal, Wiki, family-style и screenshot instructions переведены на bilingual repository module и категоризированные templates в этом репозитории.
- Focused validator теперь проверяет local packages, repository locale parity, стабильные repository anchors, запрет deprecated path и универсальность гайда.

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

Public tree, legal/privacy, Wiki, screenshots и family documentation остаются отдельными instruction domains, но их общие sources теперь собраны вместе: `docs/repository/` и `templates/repository/` владеют repository structure, а `docs/MASTER.md`, `tokens/` и `templates/design/` — interface grammar и visual evidence.

## Результат удаления

Ни одна инструкция не удалена: не найдено orphaned или действительно redundant процесса. Убраны duplicated changing values и ambiguous cross-product inheritance.

## Новый canonical read order

1. Obsidian root `AGENTS.md` и `_agents/index.md`.
2. `Дизайн-система QenTerra — применение и развитие.md` для UX/UI.
3. Design-system `AGENTS.md`, затем `docs/MASTER.md`/tokens для UX/UI или `docs/repository/STANDARD.md`/`templates/repository/` для repository documentation.
4. Product-specific Obsidian instruction.
5. Current repository source, tests, specs и rendered evidence.

## Граница проверки

Аудит проверяет static routing, token/version/package ownership, parity bilingual repository module, templates и validator behavior. Он не доказывает live Obsidian rendering, native product rendering или external publication.
