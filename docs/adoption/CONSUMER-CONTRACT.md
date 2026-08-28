# Consumer contract

Every adopting repository should keep `design-system-consumer.json` at its root. It identifies the consumer, platforms, package versions, and adopted capabilities. Intentional divergence belongs in `design-system-exceptions.json` with a stable identifier, owner, reason, exact scope, and review date.

Consumers install released packages instead of copying generated output. Local paths are permitted during coordinated development but must fail release validation. The consumer audit reports drift without mutating the project.

Compliance means the declared packages resolve, semantic tokens replace matching raw values, reusable components are used where delivered, and every exception is current. It does not by itself prove runtime rendering, keyboard behavior, VoiceOver, localization, or visual acceptance.
