# Code quality tooling

Copy only the language profile adopted by the repository and pin compatible tool versions in that product's manifest. Do not replace a working product command with a generic script: document one canonical verification command instead.

- Swift: SwiftFormat, SwiftLint, build, and tests.
- TypeScript: Prettier, ESLint, strict `tsc --noEmit`, and tests.
- Python: Ruff and pytest; Bash: ShellCheck and shfmt. These profiles are advisory until the product completes scoped adoption.

The TypeScript flat config requires `eslint`, `typescript`, `typescript-eslint`, and `globals`. Add only the packages required by the adopted profile.
