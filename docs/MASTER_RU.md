# Design System

Версия 5.1.0 · Нормативный справочник для людей и AI-агентов

## 0. Как пользоваться этим файлом

Этот документ задаёт повторно используемые UX/UI-правила для нативных приложений, сайтов и браузерных расширений.

Читайте в таком порядке:

1. Определите целевую платформу и профиль продукта.
2. Перед выбором компонентов прочитайте нужный сценарий.
3. Берите семантические токены из `tokens/*.json`; никогда не копируйте значения со скриншотов.
4. Предпочитайте нативное поведение платформы декоративной одинаковости.
5. Проверяйте все обязательные состояния, режимы доступности и границы контента.

Для графики Nyx, стикеров, обоев и pet-анимации дополнительно прочитайте `docs/brand/MASTER_RU.md`, нужный профиль Nyx и `assets/brand/manifest.json`. Nyx — единственное сохранённое семейство бренд-ассетов; графика не заменяет семантические UI-токены.

Нормативные слова:

- **обязан**: требуется для соответствия;
- **следует**: вариант по умолчанию; отклонение требует причины;
- **может**: необязательно;
- **запрещено**: недопустимо;
- **специфично для продукта**: намеренно не входит в общее ядро.

Если текст и файл токенов расходятся, точные значения берутся из токенов, а смысл поведения — из этого документа. Исправьте противоречие в той же правке.

## 1. Область системы

Design System стандартизирует семантику, поведение, доступность и доказательства. Единую оболочку приложения система не задаёт.

Общие правила охватывают цветовые и типографические роли, ритм отступов, иерархию скруглений, состояния компонентов, SF Symbols, анимацию, текст, восстановление после ошибок, доступность и QA-доказательства.

Общие правила не требуют одинаковой ширины sidebar, одного расположения Settings, общей высоты строк или одной метафоры app icon.

## 2. Принципы

### 2.1 Сначала контент

Chrome помогает задаче и не спорит с ней за внимание. Оригинальные обложки и файловый контент могут сохранять цвет; окружающий UI остаётся преимущественно графитовым и монохромным.

### 2.2 Точный статус

Показывайте только то, что система действительно знает. Не имитируйте уровень аудио, прогресс, завершение, сеть, выбор или сохранение.

### 2.3 Прямое управление с восстановлением

Действия должны работать с видимыми объектами. Рискованные действия требуют просмотра, подтверждения, Undo или восстанавливаемого места по цене последствий.

### 2.4 Узнавание важнее вспоминания

Важные разделы и действия имеют видимые подписи, пока пользователь сам не выберет compact-режим или responsive-преобразование не станет необходимым.

### 2.5 Сначала нативное

Используйте платформенные controls, menus, sheets, navigation, typography, accessibility и keyboard conventions, если они выполняют контракт. Кастомный control обязан совпадать с нативной семантикой, а не только видом.

### 2.6 Спокойно, но не мёртво

Анимация подтверждает ввод и объясняет изменение. Она короткая, прерываемая и отсутствует, если не добавляет информации.

### 2.7 Доступность — состояние, а не приложение

Reduced Motion, Reduced Transparency, Increased Contrast, keyboard focus, скринридеры, расширение текста, zoom и разница touch/pointer входят в определение компонента.

### 2.8 Один источник меняющихся значений

Точные цвета, размеры, длительности и имена токенов живут в `tokens/`. Документация ссылается на семантические роли. Generated CSS и Swift не редактируются вручную.

## 3. Основы

### 3.1 Тема

Все продукты обязаны поддерживать `System` как выбор по умолчанию, полноценную `Light` и фирменную `Dark`. Смена темы сохраняет иерархию, смысл статусов, фокус и контраст. Светлая тема не создаётся наивной инверсией тёмной.

### 3.2 Цвет

Графитовая шкала основы живёт в `tokens/foundation.json`, семантические цвета для каждой темы — в `tokens/semantic.json`.

Поверхности: `surface.content` для длинного контента, таблиц, форм и браузеров; `surface.secondary` для групп и боковых областей; `surface.raised` для карточек, selection и inspectors; `surface.chrome` для title bars, rails и toolbars; `surface.overlay` для dialogs, command panels и fallback HUD; `surface.inverted` для редкой инверсии.

Текст: `text.primary` — заголовки, значения и главные подписи; `text.secondary` — описания; `text.tertiary` — низкоприоритетные, но читаемые метаданные; `text.disabled` — недоступное, не инструкция; `text.link` — навигация с нецветовым focus/hover-affordance.

Действия: `action.primary` — одно доминирующее действие; `action.secondary` — безопасная альтернатива; `action.quiet` — контекстное; `state.destructive` — необратимое или трудно восстановимое; `state.success`, `state.warning`, `state.informative` — статус с текстом или символом; `state.recording` — продуктовая роль активного захвата.

Запрещено: absolute black на собственных поверхностях; цвета artwork как постоянный chrome; один цвет для selection/error/success/warning/recording; сырые `.red`, `.green`, `.orange` или новые HEX в product UI. Контраст проверяется отдельно в Light и Dark. Increased Contrast может усилить границы и selection без смены layout.

### 3.3 Типографика

Используйте системный шрифт. Роли заданы в `tokens/typography.json`: `display`, `screenTitle`, `modalTitle`, `sectionTitle`, `body`, `bodyEmphasized`, `row`, `rowEmphasized`, `supporting`, `metadata`, `compactMetadata`, `eyebrow`, `keycap`, `monospacedData`.

Правила:

- предпочитайте dynamic text styles фиксированным пунктам;
- не создавайте полупунктовые размеры;
- не ослабляйте важную иерархию мелким текстом;
- для меняющихся выровненных чисел используйте tabular numerals;
- держите строку чтения около 45–76 знаков;
- uppercase eyebrow краток и не несёт критическую инструкцию;
- уровни заголовков отражают структуру, а не размер.

### 3.4 Отступы

Базовый ритм — 4 пункта. `space.1` 4 — оптический micro-gap; `space.2` 8 — icon-to-label; `space.3` 12 — внутри строки и control; `space.4` 16 — группа; `space.5` 20 — ритм панели; `space.6` 24 — секции; `space.8` 32 — области страницы; `space.10` 40 и `space.12` 48 — onboarding и крупный canvas. Сначала выберите метрики компонента; не чините его negative margins на странице.

### 3.5 Размер и плотность

Профили: `compact` для утилит, таблиц и menu panels; `standard` для content apps и смешанных потоков; `comfortable` для onboarding, touch-first и важных Settings. Pointer targets могут быть визуально меньше touch targets, но остаются доступными. Платформенные значения — в `tokens/platforms.json`. Не навязывайте одну высоту строк всем продуктам.

### 3.6 Скругления

`radius.control` — controls и interactive rows; `radius.group` — cards и Settings groups; `radius.panel` — popovers, sheets и panels; `radius.hero` — важные empty states и onboarding; `radius.floating` — HUD и command panels; `radius.pill` — chips, badges и keycaps, только когда форма объясняет группировку. Максимальное скругление не заменяет иерархию.

### 3.7 Границы и разделители

Hairline разделяет плотный контент без сетки карточек. Default border определяет группы и controls; strong border — focus, selection и Increased Contrast. Focus ring не заменяется hover или selection fill. Разделители таблиц и split views стабильны.

### 3.8 Материалы и высота

Непрозрачные поверхности несут контент. Адаптивная прозрачность допустима для title bars, rails, toolbars, menus, popovers, player chrome, HUD и command/search panels. Стекло не применяется к таблицам, длинным Settings, file lists, lyrics и reading surfaces. Reduced Transparency заменяет material на named opaque fallback без смены геометрии. Высота задаётся ролью поверхности, border и occlusion; тени тонкие и только для floating layers.

### 3.9 Иконографика

SF Symbols являются единственными interface icon assets. `registry/icons.json` сопоставляет каждой семантической роли одно системное имя и minimum OS. SwiftUI и AppKit рендерят символы через system APIs. Локальный HTML-прототип получает previews из AppKit во время macOS-сборки и не определяет web icon package.

- Один смысл использует один символ во всей семье.
- Один символ не повторяется для sibling destinations.
- Icon-only controls имеют accessible name и tooltip/help.
- Прямая знакомая метафора важнее хитрого композита.
- Вес иконки совпадает с текстом и control.
- Selected state меняет fill или rendering mode, но не геометрию.
- Status icon дополняется текстом или нецветовым индикатором.

Иконки приложений делят правила построения, а не метафоры: safe zone, silhouette density, material, lighting, appearance specialization и проверку малых размеров. Каждый продукт сохраняет отдельный знак, связанный с его задачей.

### 3.10 Изображения и медиа

Сохраняйте цвет и aspect ratio оригинала. Не обрезайте информацию, чтобы скрыть проблему layout. В документации используйте privacy-safe synthetic data. Превью файлов остаются нейтральными, пока медиа не станет самой задачей. Декор не вытесняет controls на тесных размерах.

### 3.11 Компоновка

Начинайте с иерархии задачи: primary object/result, primary action, context/filters, supporting metadata, diagnostics/rare actions. Split view — для одновременных связанных контекстов, sidebar — для navigation/sources, inspector — для details, sheet — для сфокусированной задачи. Responsive описывается до локальной полировки.

Каждый layout задаёт minimum/ideal size, сжатие, wrap, menu collapse, перенос в screen/sheet, scroll ownership, focus order, 30% расширение строк и 200% web zoom.

## 4. Состояния взаимодействия

Каждый interactive component определяет default, hover, pressed, keyboard focus, selected, disabled, loading, unavailable/error, Increased Contrast и Reduced Motion/Transparency. Focus показывает, куда пойдёт keyboard input; selection — какой объект выбран; hover — временное pointer preview. Не сводите их к одному boolean.

## 5. Элементы управления

### 5.1 Кнопки

Роли: `primary` завершает или продвигает задачу; `secondary` — безопасная альтернатива; `quiet` — контекст; `destructive` — явно названное удаление; `icon` — знакомое компактное действие; `menuRow` — команда в custom menu list; `link` — навигация к docs/policy/content.

- Одна primary на поверхность.
- Подпись начинается с глагола и называет результат.
- Ellipsis только если до завершения нужен ещё ввод.
- Loading сохраняет ширину и показывает state/progress text.
- Disabled объясняет неочевидную причину.
- Destructive не становится primary из-за позиции.

### 5.2 Кнопки-иконки

Они имеют стабильную hit area, accessible label, видимый focus, hover help и не меняют геометрию. Если символ не считывается сразу, используйте текст.

### 5.3 Поля

Состояния: `pristine`, `editing`, `valid`, `invalid`, `disabled`, `readOnly`. Не показывайте ошибку до взаимодействия. Валидируйте по blur, паузе или submit по цене ошибки. Не давайте helper text прыгать. Error copy называет требование и действие. Label всегда видим; placeholder — пример. Secure fields не выдают секреты в logs, screenshots и accessibility hints.

### 5.4 Поиск

Определите scope, clear, shortcut, empty query, result count, no-results и persistence. Не делите query state между разными контекстами без явного переноса.

### 5.5 Элементы выбора

Checkbox — независимые опции; radio group — ровно один выбор; switch — немедленная постоянная настройка; segmented control — peer views/modes, не destructive actions.

### 5.6 Pickers, sliders, steppers

Picker для discrete values, slider для диапазона с полезным approximate manipulation, stepper для точного шага. Текущее значение всегда показано текстом.

### 5.7 Chips, tokens, badges, keycaps

Filter token удаляется и называет scope. Status badge содержит текст. Count badge учитывает plural rules. Keycap использует одну нотацию и пробел между modifier и key: `⌥ Space`. Chip не становится крошечной двусмысленной кнопкой.

## 6. Контейнеры и данные

### 6.1 Группа и карточка

Группируйте связанное, но не оборачивайте всё в карточки. Карточка нужна для семантической границы, независимого действия или elevated lifecycle.

### 6.2 Settings section и row

Settings row — одна accessible unit из label, optional description и trailing control. API не допускает unnamed control. Description объясняет последствие, а не повторяет label. Section header группирует решения, а не продаёт их.

### 6.3 Интерактивная строка

Общая row владеет hover, press, focus, selection, disabled и unavailable. Фичи не передают hardcoded `false`, чтобы их подавить. В строках с несколькими действиями row activation отделен от embedded links/controls. Double click и Return имеют один primary meaning там, где этого ждёт desktop.

### 6.4 Списки, таблицы, сетки и деревья

List — одномерные peers; table — выровненные сравнимые атрибуты; grid — визуальное сканирование без смысла позиции; tree — иерархия.

Таблица имеет dominant first column, visible sort direction, keyboard selection, поведение column resize, long values, empty/no-results/loading/error и accessible row/column semantics. Selection переживает sorting только для того же object. Перед bulk action сообщаются hidden selected items.

### 6.5 Плитки расширений и файлов

Когда главное — имя файла, используйте нейтральную extension tile. Не заменяйте filename сгенерированным media title. Thumbnail нужен только когда визуальный контент реально помогает selection.

### 6.6 Медиастроки

Artwork может вести строку. Title первичен, creator вторичен, codec/quality — compact metadata. Embedded links не запускают playback и не ломают multi-selection.

## 7. Навигация

Общая навигация задаёт states, icon treatment, label behavior, keyboard movement, focus, persistence и responsive transformation, но не одну оболочку.

### 7.1 Rail

Rail нужен для малого стабильного набора top-level destinations. Expanded помогает узнаванию, compact экономит место. Каждое направление имеет уникальный символ. Expansion сохраняет icon anchors и анимирует только width/label opacity. Compact не скрывает current location.

Defaults архетипов: библиотеки контента раскрывают rail, когда узнавание важнее плотности; операционные рабочие области используют compact или responsive режим; transient-утилиты обходятся без application rail вне полнооконных Settings или истории.

### 7.2 Sidebar

Для labeled sources, categories и Settings sections. Поддерживает keyboard movement, selection, scrolling и visible current item. Custom sidebar не теряет arrow navigation и screen-reader semantics.

### 7.3 Toolbar

Содержит частые контекстные действия. Search следует platform placement. Overflow явно уходит в labeled More; критические действия не исчезают в horizontal scroll.

### 7.4 Tabs и segmented navigation

Для малого числа peer views. Сохраняйте state при переключении, если этого ждут. Active tab не является кликабельной анимацией без state effect.

### 7.5 Breadcrumb и contextual Back

Breadcrumb нужен для глубокой web/document hierarchy. Native apps используют labeled contextual Back, если destination зависит от entry source. Одного chevron недостаточно.

## 8. Оверлеи и временные поверхности

### 8.1 Menu

Содержит немедленные команды. Группируйте, показывайте shortcuts, отделяйте destructive и по возможности объясняйте disabled.

### 8.2 Popover

Короткий контекстный выбор или inspector, закрываемый без потери работы. Остаётся в viewport и возвращает focus инициатору.

### 8.3 Sheet

Сфокусированная задача с input, review или несколькими решениями. Сохраняет unsaved work, если accidental dismiss дорог.

### 8.4 Dialog и alert

Alert — для interruption, permission, destructive confirmation или failure, требующего решения. Title называет ситуацию, body — последствие, actions — outcomes. Не используйте generic `OK`, когда есть result verb, и не подтверждайте безобидное reversible.

### 8.5 Toast и banner

Toast — transient completion без решения; banner — persistent status в scope поверхности или app. Они не заменяют inline field/row errors.

### 8.6 HUD и command panel

HUD передаёт transient status без кражи keyboard focus. Command/search panel может забрать focus, но сохраняет и возвращает source target до action в другом app. Multi-display placement идёт от active target window, а не mouse position.

## 9. Обратная связь и прогресс

### 9.1 Загрузка

Skeleton — когда форма контента известна; indeterminate indicator — когда длительность неизвестна; determinate progress — только по измерениям. Таймер не создаёт фальшивый progress.

### 9.2 Жизненный цикл операции

Различайте preparing, waiting, running, paused, verifying, completing, completed, failed, cancelling, cancelled, interrupted/recoverable. Actions соответствуют lifecycle. При cancellation остатка уже completed results не исчезают без явного обещания.

### 9.3 Empty и no-results

Empty означает пустую коллекцию. No-results означает, что фильтры или поиск исключили существующий контент. Им нужны разные copy и recovery.

### 9.4 Ошибки

Field error привязана к input; row error — к object; section notice — к workflow region; banner — к surface/app; alert — блокирует или требует решения. Ошибка называет: что случилось, что осталось safe/saved, что делать. Technical details уходят в optional disclosure или diagnostic export.

## 10. Базовые сценарии

### 10.1 Select → Review → Execute → Complete/Recover

Для imports, downloads, destructive batches, exports и migrations. Select показывает scope; Review — count, size, destination, conflicts и exclusions; Execute — progress и cancellation semantics; Complete — outcomes и recovery.

### 10.2 Разрушительное действие

- Мгновенно reversible: выполнить с Undo.
- Recoverable later: объяснить destination и restore.
- Destructive but scoped: confirmation с точным object/count.
- Irreversible and broad: дополнительное friction и явное последствие.

### 10.3 Запрос разрешения

До system prompt объясните выгоду. Различайте required и optional. Fallback — режим, а не ошибка.

### 10.4 Onboarding

Короткий, skippable, truthful и не делает ничего автоматически. Required и optional различаются. Trial использует isolated destination и не засоряет history/external apps.

### 10.5 Поиск и фильтры

Показывайте scope, active filters, removable tokens, clear-all, result count и recovery no-results. Критические фильтры остаются discoverable на узкой ширине.

### 10.6 Multi-selection

Следуйте platform conventions. Bulk summary показывает visible и hidden counts. Смена фильтра не применяет действие к hidden objects молча.

### 10.7 Offline и stale data

Называйте current, cached, partial и unavailable. Сохраняйте полезный cache. Retry локален и не стирает state.

### 10.8 Возврат фокуса

До focus-taking surface сохраните target context. Затем: проверьте target, закройте/deactivate surface, верните focus, выполните action, честно сообщите fallback.

### 10.9 Privacy-safe export

Дайте preview included/excluded и по умолчанию минимум данных. Не включайте transcripts, private chat, credentials, home paths и session data без явного scope и warning.

### 10.10 Settings

Это durable user choices, а не transient commands. При существенной конфигурации используйте native Settings window/scene. Embedded Settings допустимы, если status и config нужны вместе, но они соблюдают Settings grammar.

## 11. Анимация

Точные длительности и кривые — в `tokens/motion.json`. Классы: немедленная обратная связь, замена состояния, раскрытие, появление плавающей поверхности, пространственная навигация и измеряемый непрерывный прогресс.

- Анимация не меняет смысл выбора.
- Смена состояния прерываема и завершается на текущем вводе.
- Повторяющаяся декоративная анимация запрещена.
- Пружины допустимы только для нативного физического взаимодействия с ограниченным смещением; обычный интерфейс использует семантические кривые.
- Прогресс отражает реальную работу.
- Автопрокрутка останавливается и отключается при уменьшении движения.
- Режим уменьшенного движения оставляет короткую смену прозрачности или мгновенную замену, убирая масштабирование, перемещение, параллакс и каскадные задержки.

## 12. UX-тексты и локализация

### 12.1 Голос

Спокойный, прямой, конкретный и честный. Без marketing language в operational UI и без очеловечивания ошибок, когда нужна точность.

### 12.2 Подписи

Действия начинаются с глагола и называют result: `Download 2 Files`, `Reveal in Finder`, `Retry Verification`. Описания и messages — sentence case, краткие native titles — platform capitalization. Один concept имеет один термин.

### 12.3 Статус

Сообщайте actual outcome: `Copied to Clipboard` не `Inserted`; `Saved for this session` не `Saved`; `Cached results` не `Up to date`; `No speech detected` лучше internal recognition code.

### 12.4 Текст ошибки

Избегайте `Something went wrong`, `Unknown error`, `The app needs help`, generic `Configure` и internal API terms без user consequence. Называйте причину, preserved state и scoped action.

### 12.5 Подтверждение

Title спрашивает или называет последствие. Body объясняет, что изменится и что останется. Destructive label повторяет конкретный глагол.

### 12.6 Локализация

- Все user-facing strings живут в platform localization source.
- Используйте plural rules, а не concatenation.
- Даты, время, байты, decimals и lists форматируются по locale.
- Key parity проверяется автоматически.
- Layout тестируется при 30% expansion и long unbreakable values.
- HTML не вставляется через untranslated strings.
- Typed/generated localization keys лучше duplicated defaults.

## 13. Доступность

### 13.1 Клавиатура

Каждое action достижимо. Focus order следует reading/task order. Focus виден отдельно от selection. Escape закрывает reversible overlays. Return активирует selected primary object там, где это принято. Arrow keys управляют composite widgets по platform conventions. Shortcuts видны в menus/help.

### 13.2 Скринридеры

Controls имеют names, values, roles, state и actions. Связанные визуальные фрагменты группируются в смысловые units. Progress и counts анонсируются без болтовни.

### 13.3 Контраст и цвет

Обычный web text целится в WCAG AA. Native UI использует semantic colors и проверяет Increased Contrast. Status не зависит только от hue.

### 13.4 Размер текста и zoom

Веб поддерживает 200% zoom без потери controls и horizontal page scroll. Native layouts переживают text-size и localization expansion. Fixed row heights проверяются или становятся adaptive.

### 13.5 Движение и прозрачность

Reduced Motion и Reduced Transparency сохраняют понимание и interaction. Increased Contrast усиливает границы без смены иерархии.

### 13.6 Touch и pointer

Touch targets соответствуют platform minimum. Pointer UI может быть плотнее, но hit regions остаются удобными. Hover-only information доступна через focus или tap.

## 14. Платформенные слои

### 14.1 macOS

Нативные menus, commands, toolbar placement, split views, Settings scenes, file panels, Quick Look и Finder integration. Resizable windows с minimum/ideal states. Keyboard и pointer первоклассны. Без лишней модальности. Custom rails/tables воспроизводят native focus, selection и accessibility semantics.

### 14.2 iOS

Touch-first targets, Dynamic Type, safe areas, native navigation stacks, sheets и tab bars. Не сжимайте macOS density до телефона. Primary actions достижимы без hover/context menu.

### 14.3 iPadOS

Split views, sidebars, inspectors, pointer и keyboard. Опишите compact, half-width и full-width. Multitasking и Stage Manager меняют размер без пересоздания state.

### 14.4 Веб

Semantic HTML до ARIA. Keyboard, focus-visible, reduced motion, forced colors, touch, 200% zoom, print и responsive navigation. Не копируйте macOS pixel-perfect, если browser conventions яснее. CSS custom properties генерируются из semantic tokens.

### 14.5 Браузерные расширения

Popup, side panel, overlay dock, bottom sheet и options page — разные layout modes. Overlays остаются в viewport и вне clipped host containers. Host styles/scripts изолированы. Selection и hover разделены; уход указателя не меняет зафиксированный выбор. Critical controls видны на narrow widths и localization expansion.

## 15. Архетипы продуктов

Точные arrays живут в `tokens/products.json`. Выбирайте архетип по модели взаимодействия, а не по бренду; продукт может сочетать несколько архетипов, если границы между ними явны.

### 15.1 Иммерсивный контент

Для библиотек и браузеров, где доминируют постоянная иерархия контента, rich media, выбор, очереди и долгоживущее состояние. Сохраняйте адаптивные поверхности, review-first импорт, постоянные task controls, стабильные таблицы и восстанавливаемое удаление. Адаптируйте плотность и навигацию под платформу. Заменяйте повторяющиеся символы, разрозненные визуальные константы, подавленные состояния взаимодействия и обещания сохранения, которые сильнее реальности.

### 15.2 Плотные операции

Для файловых, transfer, batch и административных сценариев. Сохраняйте filename-first или object-first иерархию, сводки выбора, preflight, разрешение конфликтов, scoped progress, историю операций и системную интеграцию. Адаптируйте плотность rail, перенос toolbar, размещение проблем, локализацию и motion. Заменяйте невидимое переполнение, pristine-field errors, безымянные переключатели, тихий сброс сессии и глобальные нетипизированные ошибки.

### 15.3 Временная возможность

Для menu-bar утилит, HUD, инструментов захвата, быстрой истории и фоновых возможностей, которые показываются ненадолго. Сохраняйте честный словарь состояний, real-signal-only feedback, семантическую анимацию, privacy language, keycaps, возврат фокуса и диагностику. Адаптируйте палитру, типографику, Settings, onboarding requirements и lifecycle cards. Заменяйте принудительную тему, слишком мелкий текст, generic recovery, поддельные trial-сценарии, сломанный возврат фокуса и устаревшие visual sources.

## 16. Иконки приложений

Семейность строится на общем оптическом весе, контролируемой биоморфной или гранёной конструкции, сдержанном графитовом или монохромном материале, контрасте с учётом темы, одинаковых безопасных зонах и плотности силуэта, согласованных свете, прозрачности и глубине, а также проверке в размерах 16, 32, 64, 128, 256, 512 и 1024 пикселя. Метафоры остаются разными: не превращайте всё в плитки с буквами и не навязывайте геометрию одного продукта несвязанным понятиям.

## 17. Документация и скриншоты

Каждый продукт имеет воспроизводимый стенд скриншотов с синтетическими данными. Матрица включает системную, светлую и тёмную темы; минимальную и широкую компоновку; основной сценарий; пустое состояние; отсутствие результатов; загрузку и прогресс; ошибку и восстановление; явные снимки default, hover, focus, selected, loading, error и recovery; уменьшение движения и прозрачности, повышенный контраст и Forced Colors; проверку приватности и визуальный просмотр. Полная проверка обязана действительно запустить браузерный контракт и сравнение пикселей: отсутствие браузера или image runtime считается ошибкой, а не пропущенным успехом. Порог изменённых пикселей равен нулю; отдельно объявленный допуск канала может игнорировать не более 3/255 шума сглаживания рендерера. Скриншоты доказывают только геометрию и внешний вид, но не работу клавиатуры, скринридера, сохранения, сети и восстановления.

## 18. Управление

### 18.1 Типы изменений

- patch: уточнение или совместимое исправление;
- minor: новый токен, компонент, сценарий или платформенное правило;
- major: переименование или удаление семантического токена, изменение контракта поведения либо обязательной миграции продукта.

### 18.2 Жизненный цикл токена

1. Опишите проблему и потребителей.
2. Повторно используйте семантическую роль, если смысл совпадает.
3. Значение основы добавляется, только если существующая шкала не выражает нужное.
4. Добавьте или измените семантическое сопоставление.
5. Обновите документацию компонента и сценария.
6. Перегенерируйте CSS и Swift.
7. Запустите валидацию и визуальное сравнение.
8. Добавьте примечания по миграции и changelog.

### 18.3 Исключения

Записывают продукт и платформу, пользовательскую потребность, причину неприменимости общего правила, точную область, влияние на доступность, условие пересмотра и владельца или источник. Исключение не меняет основу молча.

### 18.4 Gate нового компонента

Проверьте, что результат нельзя собрать из существующих компонентов; анатомия и роли контента названы; обязательные состояния, клавиатура и скринридер, адаптивность и локализация, уменьшение движения и прозрачности, повышенный контраст, нативные альтернативы, тесты и скриншоты определены.

### 18.5 Устаревание

Устаревшие токены и компоненты остаются в документации на одно окно миграции с указанием замены. Валидатор может сначала предупреждать, а после объявленной major-версии — завершаться ошибкой.

### 18.6 Публичная дистрибуция пакетов

Канонический приватный репозиторий формирует один allowlisted public-репозиторий
`qenterra/packages`. Через npm он отдаёт `@qenterra/design-tokens`, а через
SwiftPM — продукты `QenTerraDesignTokens` и `QenTerraComponents`. Production-
потребители фиксируют неизменяемые SemVer-релизы; локальные пути допустимы только
для согласованной работы над Design System. Публикация требует совпадения версий,
точного release manifest, полного gate и разрешения чистыми consumer-проектами.
Релиз адаптеров не доказывает нативную отрисовку или приёмку доступности продукта.

Нативное публичное дерево намеренно разделено на две зоны. `Sources/QenTerra/`
содержит устанавливаемые токенизированные targets `QenTerraDesignTokens` и
`QenTerraComponents`. `Sources/ExploreSwiftUI/` хранит точный атрибутированный
исходный код каждой detail page из sitemap Explore SwiftUI и не является SwiftPM-target.
Файлы оригиналов неизменяемы: синхронизация может заменить их только
текущим source field с той же страницы, а offline-проверка замыкает manifest и
проверяет каждый байт и hash. Адаптация начинается командой
`scripts/explore_swiftui.py derive`, становится отдельным QenTerra-файлом, хранит ID и hash
оригинала и до stable-статуса обязана получить семантические токены, тесты,
статус доставки, версию и changelog. `sync --check` доказывает актуальность относительно
живого сайта; offline gate доказывает только целостность сохранённого snapshot.

## 19. Протокол AI-реализации

### 19.1 Кодовая система

При реализации или ревью продуктового кода прочитайте `docs/CODE_RU.md`, профиль нужного языка, архитектурный контракт продукта и его конфигурацию-источник истины. Кодовая система требует понятных человеку границ модулей, явных состояния и эффектов, нативных платформенных конвенций и раздельных automated, live и manual evidence. Она никогда не разрешает AI-артефакты внутри репозитория.

При сборке или ревью AI:

1. Читает этот файл, платформенный слой и профиль продукта.
2. Определяет основную пользовательскую задачу и цену ошибки.
3. Выбирает сценарий до компонентов.
4. Получает точные токены из JSON и сгенерированных адаптеров.
5. Перечисляет состояния и требования доступности до кода.
6. Берёт реалистичный локализованный контент, а не lorem ipsum.
7. Собирает минимальный связный набор компонентов.
8. Запускает проектные проверки.
9. Рендерит темы и ограниченные размеры.
10. Разделяет автоматические, визуальные, живые и непроверенные доказательства.

AI запрещено восстанавливать текущий интерфейс по устаревшим скриншотам; небрежно добавлять сырые цвета, длительности, скругления или источники строк; называть статическую компиляцию визуальной проверкой; считать скриншоты проверкой доступности; выдавать запасной результат за запрошенный; переносить специфичный для продукта компонент в семейное ядро без второго реального потребителя.

Профильные схемы — исполняемый контракт, а не украшение редактора. Изменение токенов обязано сохранять отсутствие циклов и совместимость типов. Метрики компонентов ссылаются на foundation; узкое исключение допустимо только с обоснованием в `components.extensions.rawMetricExceptions`. Потребители используют типизированные `DesignTokens.Color`, `DesignTokens.Typography`, `DesignTokens.Motion`, `DesignTokens.Component` или CSS-токены; CSS-рецепты подключаются отдельно, потому что нативные и продуктовые оболочки могут отличаться.

`registry/components.json` — исполняемый каталог компонентов. Его stories покрывают каждое объявленное состояние, а каждая запись честно указывает статус доставки; непокрытое состояние или выдуманный пакет завершают валидацию ошибкой. До внедрения потребитель проверяет System/Light/Dark, компактную/стандартную плотность, ограниченную ширину, длинный текст и двунаправленные раскладки. SwiftUI-потребители могут начать с доставленных примитивов кнопки, группы и интерактивной строки; нативное поведение и контекст продукта всё равно важнее декоративной одинаковости.

## 20. Сопровождение

1. Прочитайте `AGENTS.md`, этот файл, затронутые токены и доказательства продукта.
2. Добавьте или обновите ADR для нормативного изменения.
3. Меняйте канонические токены, реестры, схемы, документацию, шаблоны или фасады пакетов.
4. Для изменений Explore SwiftUI запустите `python3 scripts/explore_swiftui.py sync --write`; затем при изменении generated/public outputs запустите `python3 scripts/generate.py write` и `python3 scripts/build_public_packages.py write`.
5. Запустите `python3 scripts/verify.py`.
6. Проверьте npm-архив, Swift-продукты и затронутый consumer в нужных темах и ограничениях.
7. Обновите changelog и версию.
8. Меняйте маршрутизацию Obsidian только при смене рабочего процесса или контракта продукта; не дублируйте значения токенов.
9. Для брендовых изменений обновите манифест, сохраните покрытие Git LFS, запустите профильный Nyx QA и осмотрите оригинальный/рабочий масштаб на нужных фонах.
10. Коммитьте исходники и сгенерированные артефакты вместе после проверки.

## 21. Готовность продукта к внедрению

Продукт соответствует системе, когда семантические токены заменили локальные дубликаты; обязательные состояния компонентов реализованы; продуктовые исключения задокументированы; видимые пользователю строки локализованы; клавиатура и доступность проверены; скриншоты актуальны; пустота, загрузка, ошибка и восстановление пройдены; валидаторы сырых токенов и устаревшей документации прошли; пробелы живой проверки названы явно. Одного визуального сходства недостаточно.

Внедрение начинается с consumer manifest и read-only doctor. Продукт объявляет платформы, корни исходников, ожидаемые локальные адаптеры и отдельный файл исключений. Отчёт отделяет ошибки схем/границ от находок и никогда не записывается внутрь consumer. Покрытые Swift-правила находят сырые числовые цвета, длительности анимации и радиусы углов вдобавок к CSS hex-цветам. Исключение совпадает с точными rule/path, объясняет реальное ограничение и имеет условие пересмотра. Успешный статический отчёт доказывает только покрытые правила исходников; он не подтверждает нативную отрисовку, accessibility API, permissions, persistence или recovery.

Интерфейсные иконки берутся из `registry/icons.json`: один переиспользуемый semantic ID, категория, meaning, имя SF Symbol и minimum OS. Apple-platform consumers используют системный символ напрямую. Символ не заменяет visible label при неоднозначном действии или результате.

Handoff в дизайн-инструмент строится только из детерминированных файлов `generated/figma/`. Импортёр сохраняет названия коллекций, modes и types, сообщает о неподдерживаемых полях и сначала работает со scratch-файлом. Generated JSON не доказывает публикацию Figma library. Временный brand browser служит только поиску и не может записываться в репозиторий.
