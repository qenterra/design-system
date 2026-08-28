# Каталог компонентов

Каталог задаёт ожидаемый словарь интерфейса, но не требует от каждого продукта всех компонентов. Продукт берёт только обоснованные его задачами элементы, соблюдая общий контракт и адаптер платформы.

## Действия

| Компонент | Назначение | Обязательный контракт |
| --- | --- | --- |
| Primary button | Главное завершение/продвижение | Одна на focused surface; loading, причина disabled, focus |
| Secondary button | Безопасная альтернатива | Стабильная иерархия рядом с primary |
| Quiet button | Контекстное маловажное | Hover/focus background; текст, если иконка неясна |
| Destructive button | Трудно восстановимый итог | Точный глагол, последствие, confirmation/Undo по риску |
| Icon button | Знакомое компактное действие | Accessible name, tooltip/help, стабильная hit area |
| Split button | Default и связанные альтернативы | Default безопасен и част; menu имеет keyboard semantics |
| Link | Навигация или docs | Различим на hover/focus не только цветом |
| Menu row | Команда в custom surface | Role, shortcut, disabled reason, отделение destructive |

## Текст и формы

| Компонент | Назначение | Обязательный контракт |
| --- | --- | --- |
| Text field | Короткое значение | Постоянный label; pristine/editing/valid/invalid |
| Secure field | Секрет | Без утечки в logs/screenshots; явный reveal |
| Text area/editor | Многострочный контент | Resize/scroll ownership, undo, selection, long text |
| Search field | Запрос в named scope | Clear, shortcut, count, no-results, persistence |
| Token field | Набор discrete values | Keyboard removal, overflow, duplicate prevention |
| Number field | Точное число | Locale, min/max, units, частичный invalid input |
| Date/time picker | Дата или время | Locale, timezone, keyboard, unavailable ranges |
| File/folder picker | Путь под контролем человека | Security scope, recent state, recovery inaccessible path |
| Drop zone | Прямой ввод файлов/данных | Keyboard alternative, accepted types, review до mutation |

## Выбор и регулировка

| Компонент | Назначение | Обязательный контракт |
| --- | --- | --- |
| Checkbox | Независимый Boolean | Label входит в control; mixed по смыслу |
| Radio group | Один из вариантов | Arrow navigation, group label, one selected |
| Switch | Немедленная durable setting | Ясное последствие; без Apply, если не deferred |
| Segmented control | Малый peer mode/view set | Selection виден формой; не скрывает destructive |
| Picker/select | Discrete list | Current value, keyboard menu, long labels |
| Slider | Приблизительный диапазон | Текстовое value, keyboard increments, min/max |
| Stepper | Точные шаги | Текстовое value, bounds, press-repeat |
| Rating | Упорядоченное preference | Нецветовое value и keyboard; редко |

## Компактные метаданные

| Компонент | Назначение | Обязательный контракт |
| --- | --- | --- |
| Badge | Count/status | Plural/localization, не только цвет |
| Filter token | Active removable filter | Scope name, remove, keyboard overflow |
| Chip | Категория/действие | Поведение явно, не decorative ambiguity |
| Keycap | Shortcut | Одна нотация, screen-reader expansion, platform mapping |
| Extension tile | Тип файла | Нейтрален, filename первичен |
| Avatar/artwork | Личность/медиа | Fallback, privacy, alt/accessibility |

## Навигация

| Компонент | Назначение | Обязательный контракт |
| --- | --- | --- |
| Rail | Стабильные top-level destinations | Compact/expanded, unique symbols, current-location cue |
| Sidebar | Labeled sources/sections | Arrow navigation, selection, resize/scroll |
| Toolbar | Частые contextual actions | Overflow priority, keyboard/menu parity, wrapping |
| Tab bar | Peer destinations/views | Current state, touch targets, preserved state |
| Breadcrumb | Глубокая иерархия | Current, truncation, keyboard links |
| Contextual Back | Возврат к entry source | Видимый label при неочевидной history |
| Pagination | Большой discrete result set | Current/total, disabled bounds, URL state в web |
| Step indicator | Порядок setup/task | Required/optional, current/completed/error |

## Контейнеры

| Компонент | Назначение | Обязательный контракт |
| --- | --- | --- |
| Group | Связанный контент | Heading/label, spacing, без лишней elevation |
| Card | Независимый object/action lifecycle | Ясная граница и action ownership |
| Settings section | Связанные durable choices | Title, optional description, stable rows |
| Settings row | Label + consequence + control | Одна accessible unit; unnamed control невозможен |
| Inspector | Context detail/editing | Selection relation, resize, focus return |
| Split view | Связанные contexts | Minimums, divider accessibility, persistence |
| Scroll region | Владелец overflow | Visible affordance, focus, без nested scroll |
| Disclosure/accordion | Optional detail | Expanded, keyboard, reduced motion, не скрывает critical |

## Коллекции и данные

| Компонент | Назначение | Обязательный контракт |
| --- | --- | --- |
| List | Одномерные peers | Selection/action, empty/loading/error |
| Table | Сравнимые fields | Sort, resize, keyboard, accessible headers |
| Grid | Визуальное сканирование | Reading order, adaptive columns, selected/focus |
| Tree | Иерархия | Disclosure, levels, arrows, partial loading |
| Timeline/history | Операции по порядку | Time/order, current/interrupted/completed |
| Activity row | Текущая операция | Progress, pause/resume/cancel, retained completed |
| Media row | Artwork + metadata | Playback отделён от embedded links |
| File row | Filename + operations | Original name первично, conflict/status явен |
| Chart | Количественная связь | Text/table alternative, units, нецветовые series |

Общие поверхности интерактивных строк разрешают состояния в одном порядке: disabled или unavailable, selected, hover, затем default. Focus независимо управляет границей; selected-строка сохраняет сильную нецветовую границу. `InteractiveRowState` и `InteractiveRowSurface` задают этот контракт в SwiftUI.

## Обратная связь и статус

| Компонент | Назначение | Обязательный контракт |
| --- | --- | --- |
| Inline help | Локальное объяснение | Не заменяет label; доступно по focus |
| Field error | Один invalid input | После interaction; requirement + recovery |
| Row error | Сбой object | Object опознаваем; retry/details |
| Inline notice | Локальный non-blocking state | Scope и next action |
| Banner | Persistent state surface/app | Severity, scope, dismiss/recovery |
| Toast | Transient completion | Без decision; screen-reader announcement |
| Status badge | Compact lifecycle | Symbol/shape + words |
| Empty state | Пустая коллекция | Cause/context и primary next action |
| No-results | Query исключил контент | Clear filters/query и retain context |
| Skeleton | Известная форма loading | `aria-busy`, reduced motion, без false structure |
| Spinner | Неизвестное короткое ожидание | Label по смыслу; не fake progress |
| Progress bar | Измеренное completion | Numeric/value semantics, lifecycle actions |

## Оверлеи

| Компонент | Назначение | Обязательный контракт |
| --- | --- | --- |
| Tooltip/help | Дополнительное объяснение | Hover/focus, delay, dismiss, не critical-only |
| Menu/context menu | Немедленные команды | Keyboard, shortcuts, grouping, disabled/destructive |
| Popover | Короткий выбор/detail | Viewport clamp, dismissal, focus return |
| Sheet | Focused input/review | Unsaved work, hierarchy, focus trap |
| Alert | Blocking situation | Specific title, consequence, concrete actions |
| Confirmation dialog | Рискованный итог | Exact scope/count и what remains |
| HUD | Non-focus transient status | Real signal, не ловит pointer снаружи |
| Command/search panel | Focus-taking fast action | Target capture/restore, Escape, count, keyboard-first |

## Продуктовые архетипы

| Архетип | Общий контракт | Типичный контекст |
| --- | --- | --- |
| Persistent player | Стабильный transport/status layer | Медиатека |
| Playback queue | Ordered selection, reorder, undo, unavailable | Упорядоченный контент |
| Preflight summary | Scope/count/size/destination/conflicts | Пакетная операция |
| Conflict resolver | Safe default и explicit alternatives | Передача файлов или данных |
| Recording HUD | Real signal, timer, state, non-focus | Активный захват |
| Quick history | Search, selection, insert/copy, recovery | Временная утилита |
| Model lifecycle card | Download/verify/install/load/recovery/license | Локальная возможность |

## Приёмка компонента

Компонент принят, только если его назначение, anatomy, content rules, semantic tokens, mandatory states, interaction, keyboard, screen-reader behavior, responsive transformation, localization expansion, reduced settings и verification cases задокументированы и реализованы на целевой платформе.
