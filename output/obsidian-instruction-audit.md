# Obsidian app and extension instruction audit

Scope: 19 current files whose names begin with Cadence, Lilt, Unspool, Browser extensions, or Repository.

Baseline: 1,034 lines and 86,915 Unicode characters before synchronization.

## Verdict

The corpus was large but not gratuitously duplicated at the file level. Each retained file has a distinct trigger: product domain, repository publication layer, browser-extension engineering phase, or exceptional history-reconstruction workflow. Deleting files to make the count look prettier would merge unrelated safety boundaries and make agents read more irrelevant text.

The actual problem was source ownership. Shared design facts flowed transitively through Cadence instructions, so Lilt and Unspool could inherit a stale product-specific interpretation. Exact palette and timing values were also duplicated in Cadence prose while the new machine-readable source did not exist.

## Corrected defects

- Added one canonical routing instruction for application, site, and extension UX/UI.
- Replaced Lilt's inheritance from Cadence with an explicit Lilt product profile in the design-system repository.
- Replaced Unspool's cross-product visual lookup with its own canonical product profile.
- Removed duplicated exact palette and motion values from the Cadence visual instruction; product geometry remains local.
- Connected browser-extension UI rules to web and browser-extension platform adapters.
- Separated public-document structure from visual/interface design-system ownership.
- Connected screenshot instructions to the canonical screenshot matrix.
- Added component and product-profile working templates without copying token values.
- Added a focused read-only validator with negative self-tests for missing files, version drift, and missing instruction references.
- Updated Obsidian routing and README documentation.

## Retained intentionally

### Cadence domain files

Albums, Artists, Now Playing/Queue/Lyrics, Tags/Smart Collections, library visual hierarchy, and the main app-development map remain separate because they encode different product contracts and verification gates. Product-specific geometry, playback behavior, artwork policy, and navigation semantics do not belong in the family foundation.

### Lilt and Unspool development maps

Both retain privacy, runtime, platform, storage, and live-acceptance rules. Only shared visual ownership moved to the family system.

### Unspool history reconstruction

The reconstruction instruction is near the corpus line limit but has a narrow destructive/history trigger and must not be folded into normal development guidance. Its historical commit vocabulary is not a design source.

### Browser-extension files

Architecture, UI/motion, localization, Pages/screenshots, and release audit remain separate phases with independent failure modes. The new family platform layer supplies semantics; extension files keep host-page isolation, viewport, manifest, packaging, and browser-specific boundaries.

### Repository files

Public tree, legal/privacy, Wiki, screenshots, and family documentation remain separate from product UI. `repository-documentation-standard` owns publication structure; `qenterra-design-system` owns interface grammar and visual evidence requirements.

## Deletion result

No instruction file was deleted. The audit found no orphaned or truly redundant app/extension process whose removal would improve the system. Duplicated changing values and ambiguous cross-product inheritance were removed instead.

## New canonical read order

1. Obsidian root `AGENTS.md` and `_agents/index.md`.
2. `Дизайн-система QenTerra — применение и развитие.md` for UX/UI work.
3. Design-system `AGENTS.md`, `docs/MASTER.md`, platform layer, and product profile.
4. Product-specific Obsidian instruction.
5. Current repository source, tests, specifications, and rendered evidence.

## Verification boundary

The audit verifies static routing, token/version ownership, template coverage, and validator behavior. It does not prove live Obsidian rendering or production migration of the three applications.
