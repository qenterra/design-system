# Repository templates

Copy only the files a target repository genuinely needs, then replace every placeholder and remove unused optional sections.

- `readme/`: native macOS and browser-extension profiles.
- `root/`: changelog, contributing, license, privacy, security, terms, and third-party notices.
- `docs/`: contributor-facing architecture, building, dependencies, troubleshooting, and documentation index.
- `github/`: Funding, issue, and pull-request templates. Preserve their expected `.github/` destination when copying.
- `wiki/`: generic native GitHub Wiki core. Product-specific pages belong to the product.

Placeholders use braces, for example `{PRODUCT_NAME}`, and are intentional only inside template files. Generated documentation and adopted product documents must not contain unresolved placeholders.

These templates are consistency aids, not verified product facts or legal advice. Recheck current source, permissions, storage, dependencies, distribution status, and release artifacts before use.
