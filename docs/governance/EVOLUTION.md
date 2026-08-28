# Design System evolution

Design System evolves through reviewed reusable contracts, not by silently collecting whatever happened to work in the last product.

## Promotion contract

A candidate can become canonical only when it is useful across unrelated consumers, contains no product business logic, follows native platform behavior, and has explicit accessibility and localization constraints. The change must include:

1. a foundation, component, pattern, icon, or package contract;
2. canonical token/source changes;
3. registry metadata with supported platforms and truthful delivery status;
4. automated tests and named manual checks where automation cannot prove the behavior;
5. a delivery mapping in `registry/packages.json` when it is installable;
6. version and changelog classification.

Consumer code is evidence for a candidate, not canonical source. Reimplement the generalized contract in this repository after removing project-specific content and assumptions.

## Lifecycle

- **Candidate:** observed reuse opportunity; remains in the consumer.
- **Proposed:** universal contract and affected platforms are documented.
- **Delivered:** implementation, tests, registry, package mapping, and clean-consumer proof are complete.
- **Deprecated:** replacement and migration window are documented.
- **Removed:** major release only, with changelog and migration guidance.

Improvements update existing packages when compatible. A new package is created only when it has a distinct consumer boundary, ownership, versioned API, tests, and release need; directory enthusiasm is not architecture.
