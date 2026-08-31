# Внедрение в продукт

Consumer doctor — read-only помощник миграции, а не автоматический значок соответствия. Скопируйте в продукт `templates/design/design-system-consumer.json` и `design-system-exceptions.json`, замените все плейсхолдеры и запустите:

```bash
python3 /path/to/design-system/scripts/audit_consumer.py /path/to/product --output /private/tmp/design-system-product-report.json
```

Отчёт проверяет заявленные released packages и capabilities, границы исходников, CSS hex-цвета, числовые Swift-цвета, SwiftUI-радиусы и длительности анимации, а также узко документированные исключения. Скрипт не меняет продукт и отказывается записывать отчёт внутрь дерева consumer.

## Порядок внедрения

1. Создайте manifest и честно зафиксируйте исключения.
2. Подключите версионированный публичный npm- или SwiftPM-пакет; локальный путь используйте только при изменении самой Design System.
3. Замените дубли семантических значений до специфичной геометрии продукта.
4. Перенесите общие controls и состояния по доставленным registry contracts; specification-only entries не являются устанавливаемым кодом.
5. Запустите нативные для продукта build, accessibility, localization и recovery проверки.
6. Явно назовите live/manual gaps: чистый doctor report не доказывает отрисованный продукт.

## Состояния результата

- `passed`: заявленные адаптеры найдены, покрытые статические правила не имеют необъяснённых нарушений.
- `failed`: схемы, границы исходников, адаптеры или сырые значения требуют действий.
- exception: узкая пара rule/path имеет причину и условие пересмотра; это оформленный долг, а не волшебное отпущение грехов.

## Источник пакета и аутентификация

Production-потребители фиксируют неизменяемый SemVer-релиз из
`https://github.com/qenterra/design-system` или npm-пакета
`@qenterra/design-tokens`. Оба источника публичны и не требуют read credentials.
Локальные пути нужны для согласованной работы над самой Design System, а не как
скрытая production-зависимость. Чистая установка пакета доказывает только
доступность зависимости и API.
Нативные build, rendering, accessibility, permissions, persistence и recovery
продукта по-прежнему требуют отдельных доказательств.
