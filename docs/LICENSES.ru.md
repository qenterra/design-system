# Стандарт лицензий

## Границы

Проверяйте лицензии source, binaries, packages, models, fonts, icons, images, audio, video, datasets, documentation, generated output и downloaded runtime content. Package-manager manifest покрывает только объявленные в нём поля.

Этот справочник помогает инженерной проверке и не заменяет юридическую консультацию.

## Выбор лицензии проекта

Выберите лицензию до публичного распространения. Зафиксируйте точный SPDX identifier, правообладателя, политику года, patent terms, обязанности раскрытия source и совместимость с bundled dependencies. `UNLICENSED` или proprietary notice должны прямо запрещать распространение без разрешения.

Не копируйте лицензию из другого репозитория из-за похожего продукта. Публичная доступность source не создаёт open-source license.

## Проверка зависимостей

Для каждой прямой runtime и build dependency зафиксируйте name, pinned или resolved version, source, SPDX identifier, copyright notice, use, delivery form и update owner. Проверяйте transitive dependencies, если artifact включает их или лицензия требует notice либо source.

Блокируйте packages без условий, с несовместимыми copyleft obligations, с non-commercial restrictions, конфликтующими с распространением, или с непроверяемым source.

## Ассеты, модели и данные

Зафиксируйте creator, source, license, modifications, attribution text, territory или platform restrictions и право распространения artifact. Отделяйте лицензию инструмента от лицензии его output.

Системные SF Symbols остаются ассетами Apple. Используйте system APIs в software для платформ Apple. Не используйте SF Symbols в app icons, logos, trademarks или универсальном web icon package. Сгенерированные Design System previews относятся к локальному прототипу macOS-приложения и не являются повторно используемым source artwork.

## SPDX и metadata файлов

Используйте стандартные SPDX identifiers в manifests. Добавляйте headers `SPDX-License-Identifier`, только если политика репозитория или выбранная лицензия требует per-file headers. Не меняйте сторонние copyright или license text.

Generated files называют generator и наследуют лицензию source и generator, если другой обязательный term не применяется. Vendored files сохраняют upstream notices и source URL.

## Notices и source offers

`THIRD_PARTY_NOTICES.md` перечисляет поставляемые или загружаемые сторонние материалы и воспроизводит обязательные notices. Включайте полные license texts, когда этого требуют условия. Предоставляйте source offer, modification notice, relinking material или attribution UI, если применимая лицензия этого требует.

Notices должны быть доступны в распространяемом artifact. Файл репозитория, который не попадает в поставку, не выполняет обязанность notice внутри приложения или installer.

## Решения о совместимости

Проверяйте совместимость лицензии проекта с каждым combined, linked, bundled или modified work. Рассматривайте plugins, dynamic libraries, models и datasets по их условиям и способу доставки. Неясные или дорогие решения фиксируйте в ADR и перед релизом передавайте на квалифицированное ревью.

## Барьер релиза

Перед релизом:

1. Сгенерируйте или проверьте dependency inventory по resolved graph.
2. Сравните shipped artifact с notice inventory.
3. Проверьте license files, SPDX metadata, attribution, source offers и asset restrictions.
4. Просканируйте archives на неучтённые fonts, media, models и vendored code.
5. Зафиксируйте reviewer, date, command, artifact digest и unresolved legal questions.

## Удаление и обновления

Удаление зависимости также удаляет неиспользуемые code, binaries, notices, source offers и cached downloadable artifacts, если политика это допускает. Обновление повторяет compatibility и notice review: знакомый package может сменить лицензию между версиями.
