# Версии продуктовых релизов и установщики

Этот справочник задаёт общий формат версий и контракт macOS-установщика для
продуктов QenTerra. Репозиторий продукта владеет конкретными значениями, а QDS —
форматом, схемой, шаблоном и read-only аудитом.

## Канонический manifest

Каждый публикуемый продукт хранит один `qds-release.json` в корне репозитория.
Начинайте с `templates/release/qds-release.json` и проверяйте его по
`schemas/product-release.schema.json`. Не создавайте независимо редактируемые
копии release-значений в shell-скриптах, Xcode settings, документации и
workflow-файлах. Эти поверхности читают manifest или сверяются с ним.

Запускайте read-only аудитор из QDS:

```sh
python3 path/to/qds/scripts/audit_release_contract.py path/to/product
```

Необязательный машинный отчёт записывается только за пределами репозитория
продукта. Аудитор отклоняет внутренний output path, чтобы проверка незаметно не
меняла объект, который якобы проверяет.

## Формат версий

Во всех поверхностях используются эти формы:

| Поверхность | Stable | Пример prerelease |
| --- | --- | --- |
| Marketing version | `1.0.0` | `0.2.0` |
| Build | положительное десятичное целое | `2` |
| Public version | `1.0.0` | `0.2.0-beta.1` |
| Git tag | `v1.0.0` | `v0.2.0-beta.1` |
| Публичное название | `Cadence 1.0.0 (14)` | `Cadence 0.2.0 Beta 1 (2)` |

Допустимые channels: `stable`, `alpha`, `beta` и `rc`. У stable-релиза нет
iteration. Prerelease требует положительный iteration и использует строчные
`alpha.N`, `beta.N` или `rc.N` в машинной версии. Xcode
`MARKETING_VERSION` содержит marketing version, а `CURRENT_PROJECT_VERSION` —
build. Public prerelease suffix не входит ни в одно из этих полей.

Имена артефактов выводятся детерминированно:

- `{ArtifactStem}-{PublicVersion}-{Architecture}.dmg`
- `{ArtifactStem}-{PublicVersion}-{Architecture}.zip`
- `{ArtifactStem}-{PublicVersion}-SHA256SUMS.txt`

Изменяемые имена с `latest` не публикуются как каноническое release-доказательство.

## Контракт macOS-установщика

Прямой macOS-релиз использует DMG с приложением и видимым alias на
`Applications`. Finder window может иметь сдержанный продуктовый фон, но обязан
сохранять настоящую иконку приложения, очевидное направление drag, читаемые
подписи, нативное управление клавиатурой и указателем и достаточный контраст.
Декор не заменяет инструкцию по установке.

Если Finder background является изображением, объявляйте
`installer.background` с `kind: "image"` и `scaleFactors: [1, 2]`. DMG обязан
содержать настоящие представления 72 DPI и 144 DPI, а не растянутый bitmap одного
разрешения. Поле `background` можно не указывать, если продукт использует нативный
canvas Finder.

Manifest фиксирует архитектуру и минимальную версию macOS. DMG, update archive
и файл checksums используют точно объявленные имена. Update archive собирается
из того же app bundle, что и DMG; перед публикацией проверяются оба payload.

## Правда о подписи и распространении

Указывайте `ad-hoc`, `developer-id` или `app-store` signing и отдельно состояние
notarization. Ad-hoc сборка обязана объявлять `notarized: false` и включать
Gatekeeper disclosure. Любая прямая ненотаризованная загрузка требует такого же
предупреждения рядом с download и installation instructions. Нельзя намекать на
Apple review, notarization или проверку личности, которых не было.

Developer ID signing, отправка на notarization, stapling и Gatekeeper assessment
— разные release gates. Успешная сборка и красивый DMG не доказывают ни один из
них. Store-релизы используют собственный signing и packaging path, а не набор
утверждений прямой загрузки.

## Release-доказательства

До публикации проверьте schema и semantic alignment, версии Xcode, minimum OS,
architecture, bundle identifier, имена артефактов, signing state, notarization
state, равенство payload в архивах и SHA-256 checksums. Git tag и release title
создаются из manifest. После публикации release читается обратно, а его assets
и prerelease status сравниваются с тем же источником.

Автоматические gates не доказывают drag interaction в Finder, первый запуск на
чистом Mac, формулировку Gatekeeper, установку обновления, VoiceOver output или
реальный playback path. Фиксируйте это как live checks или manual gaps, а не
сжимайте всё в слово «проверено».
