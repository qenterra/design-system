# Стандарт коммитов

## Единица истории

Коммит фиксирует одно проверяемое изменение. Храните вместе реализацию, regression coverage, generated counterparts и документацию, нужную для понимания изменения. Разделяйте несвязанные formatting, dependency updates, refactors и behavior.

Репозиторий должен собираться или проходить документированный промежуточный gate на каждом коммите, кроме явно отмеченной приватной ветки реконструкции.

## Заголовок

Используйте Conventional Commits:

```text
type(optional-scope): imperative outcome
```

Допустимые types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore` и `revert`. Добавляйте scope, когда он помогает найти владельца: `icons`, `swift`, `web`, `brand` или `release`. Пишите конкретный заголовок со строчной буквы после двоеточия и без точки в конце.

## Тело

Добавьте body, если diff не объясняет причину, ограничение, влияние на данные или отклонённый вариант. Пишите активным залогом. Опишите текущее поведение и изменение. Не вставляйте test logs, meeting notes, prompts или перечень файлов.

```text
fix(search): restore focus after dismissing results

Return focus to the search field after Escape closes the result list. This keeps keyboard navigation in the active task.
```

## Несовместимые изменения

Добавьте `!` после type или scope и footer `BREAKING CHANGE:`, когда потребителю нужна миграция.

```text
feat(icons)!: use SF Symbol names as icon values

BREAKING CHANGE: QDSIcon raw values now contain SF Symbol system names. Remove code that treats them as asset identifiers.
```

Назовите старый контракт, замену, обязательное действие потребителя и первую совместимую версию.

## Ссылки и trailers

Используйте ссылки на issue или decision, только если они ведут к устойчивой записи. Машиночитаемые trailers размещайте после body:

```text
Refs: #184
ADR: docs/decisions/0004-symbol-registry.md
Co-authored-by: Name <address>
```

Не выдумывайте автора, ревьюера, issue или verification claim.

## Generated files и assets

Коммитьте generated output вместе с породившим его source, если репозиторий хранит generated output. Generated-only commit называет исходную ревизию или команду. Изменение ассета включает manifest metadata, license records и use-size validation.

## Проверка перед коммитом

Просмотрите staged diff, а не только working tree. Проверьте secrets, personal data, tool artifacts, temporary paths, unrelated changes, stale generated files и missing notices. Запустите минимальную полную команду проверки для staged unit.

## Revert и исправление истории

Используйте `revert: <original subject>` и сохраняйте сгенерированный body `This reverts commit …`. Объясняйте частичный revert. Перед переписыванием общей истории создайте проверенную резервную копию, определите точное remote state и используйте `--force-with-lease`. Публикация или переписывание истории требуют явного разрешения.
