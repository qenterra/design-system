from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from scripts.package_release import (
    build_release_manifest,
    canonical_version,
    classify_remote_ref,
    tree_digest,
    validate_package_payload,
    validate_version_alignment,
    main as package_release_main,
)


class PackageReleaseContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary_directory.name)
        self._write("VERSION", "1.12.0\n")
        self._write("package.json", json.dumps({"version": "1.12.0"}))
        self._write(
            "packages/css/package.json",
            json.dumps({"name": "@qenterra/design-tokens", "version": "1.12.0"}),
        )
        self._write(
            "packages/css/tokens.json",
            json.dumps(
                {
                    "foundation": {"meta": {"version": "1.12.0"}},
                    "semantic": {"meta": {"version": "1.12.0"}},
                }
            ),
        )
        self._write("packages/css/LICENSE", "Internal use only.\n")
        self._write("packages/css/README.md", "# CSS package\n")
        self._write(
            "packages/css/icons.json",
            json.dumps({"version": "1.12.0", "icons": [{"id": "check"}]}),
        )
        self._write("packages/css/tokens.css", ":root {}\n")
        self._write("packages/css/recipes.css", ".qds {}\n")
        self._write("packages/swift/LICENSE", "Internal use only.\n")
        self._write("packages/swift/Package.swift", "// swift-tools-version: 5.9\n")
        self._write("packages/swift/README.md", "# Swift package\n")
        self._write(
            "packages/swift/Sources/QenTerraDesignTokens/QDSGeneratedTokens.swift",
            'public enum QDS { public static let version = "1.12.0" }\n',
        )
        self._write("packages/swift/Tests/PackageTests.swift", "import Testing\n")

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def _write(self, relative_path: str, content: str) -> Path:
        path = self.root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return path

    def test_canonical_version_rejects_non_semver(self) -> None:
        self._write("VERSION", "next\n")
        with self.assertRaisesRegex(ValueError, "semantic version"):
            canonical_version(self.root)

    def test_version_drift_is_reported_for_every_distribution_surface(self) -> None:
        self._write(
            "packages/css/package.json",
            json.dumps({"name": "@qenterra/design-tokens", "version": "1.11.0"}),
        )

        errors = validate_version_alignment(self.root)

        self.assertIn("packages/css/package.json version 1.11.0 != 1.12.0", errors)

    def test_generated_token_family_version_drift_is_reported(self) -> None:
        self._write(
            "packages/css/tokens.json",
            json.dumps({"foundation": {"meta": {"version": "1.11.0"}}}),
        )

        errors = validate_version_alignment(self.root)

        self.assertIn("packages/css/tokens.json foundation version 1.11.0 != 1.12.0", errors)

    def test_css_payload_rejects_unlisted_file(self) -> None:
        self._write("packages/css/internal-audit.md", "private\n")

        errors = validate_package_payload(self.root, "css")

        self.assertTrue(any("unexpected CSS package file" in error for error in errors))

    def test_swift_payload_rejects_lfs_pointer(self) -> None:
        self._write(
            "packages/swift/Sources/QenTerraDesignTokens/Bad.swift",
            "version https://git-lfs.github.com/spec/v1\n",
        )

        errors = validate_package_payload(self.root, "swift")

        self.assertTrue(any("Git LFS pointer" in error for error in errors))

    def test_swift_payload_rejects_denied_build_state(self) -> None:
        self._write("packages/swift/.swiftpm/configuration/registries.json", "{}\n")

        errors = validate_package_payload(self.root, "swift")

        self.assertTrue(any("denied path" in error for error in errors))

    def test_tree_digest_is_stable_and_content_sensitive(self) -> None:
        first = tree_digest(self.root / "packages/css")
        second = tree_digest(self.root / "packages/css")
        self._write("packages/css/README.md", "Changed\n")

        self.assertEqual(first, second)
        self.assertNotEqual(first, tree_digest(self.root / "packages/css"))

    def test_release_manifest_records_payload_hashes_without_manual_claims(self) -> None:
        tarball = self._write("package.tgz", "archive bytes")

        manifest = build_release_manifest(
            self.root,
            source_sha="a" * 40,
            swift_tree_sha="b" * 40,
            npm_tarball=tarball,
        )

        self.assertEqual(manifest["version"], "1.12.0")
        self.assertEqual(manifest["sourceSha"], "a" * 40)
        self.assertEqual(manifest["swift"]["treeSha"], "b" * 40)
        self.assertEqual(manifest["status"], "verified")
        self.assertIn("consumer product runtime", manifest["manualNotProven"])

    def test_remote_ref_classification_is_idempotent(self) -> None:
        self.assertEqual(classify_remote_ref(None, "a" * 40), "missing")
        self.assertEqual(classify_remote_ref("a" * 40, "a" * 40), "matching")
        self.assertEqual(classify_remote_ref("b" * 40, "a" * 40), "conflict")

    def test_remote_ref_conflict_cli_fails_closed(self) -> None:
        status = package_release_main(
            [
                "classify-ref",
                "--existing-sha",
                "b" * 40,
                "--expected-sha",
                "a" * 40,
            ]
        )

        self.assertEqual(status, 1)


class PackageMetadataTests(unittest.TestCase):
    repository_root = Path(__file__).resolve().parents[1]

    def test_css_package_is_private_registry_ready(self) -> None:
        package = json.loads(
            (self.repository_root / "packages/css/package.json").read_text(encoding="utf-8")
        )

        self.assertNotIn("private", package)
        self.assertEqual(package["license"], "UNLICENSED")
        self.assertEqual(
            package["repository"],
            {
                "type": "git",
                "url": "git+https://github.com/qenterra/design-system.git",
                "directory": "packages/css",
            },
        )
        self.assertEqual(
            package["publishConfig"],
            {
                "registry": "https://npm.pkg.github.com",
                "access": "restricted",
            },
        )
        self.assertEqual(
            package["files"],
            [
                "LICENSE",
                "README.md",
                "icons.json",
                "recipes.css",
                "tokens.css",
                "tokens.json",
            ],
        )

    def test_root_routes_only_qenterra_scope_to_github_packages(self) -> None:
        root_package = json.loads(
            (self.repository_root / "package.json").read_text(encoding="utf-8")
        )
        npmrc = (self.repository_root / ".npmrc").read_text(encoding="utf-8")

        self.assertEqual(root_package["workspaces"], ["packages/css"])
        self.assertEqual(
            npmrc,
            "@qenterra:registry=https://npm.pkg.github.com\n",
        )
        self.assertNotIn("authToken", npmrc)

    def test_css_export_smoke_check_executes_real_package(self) -> None:
        result = subprocess.run(
            [
                "node",
                str(self.repository_root / "tests/package-css-smoke.mjs"),
                str(self.repository_root / "packages/css"),
            ],
            cwd=self.repository_root,
            capture_output=True,
            text=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("CSS package smoke check passed", result.stdout)


class SwiftPackageTests(unittest.TestCase):
    repository_root = Path(__file__).resolve().parents[1]

    def test_swift_manifest_preserves_supported_contract(self) -> None:
        manifest = (self.repository_root / "packages/swift/Package.swift").read_text(
            encoding="utf-8"
        )

        self.assertIn(".macOS(.v13)", manifest)
        self.assertIn(".iOS(.v16)", manifest)
        self.assertEqual(manifest.count(".library("), 1)
        self.assertNotIn("dependencies:", manifest.split("targets:", 1)[0])

    def test_swift_distribution_has_policy_and_remote_usage(self) -> None:
        license_text = (self.repository_root / "packages/swift/LICENSE").read_text(
            encoding="utf-8"
        )
        readme = (self.repository_root / "packages/swift/README.md").read_text(
            encoding="utf-8"
        )

        self.assertIn("proprietary", license_text.lower())
        self.assertIn("qenterra/design-system-swift.git", readme)
        self.assertIn("QDSContractCheck", readme)
        self.assertIn("QDSInteractiveRowSurface", readme)
        self.assertIn("read-only", readme)

    def test_repository_swift_payload_contains_only_distribution_files(self) -> None:
        errors = validate_package_payload(self.repository_root, "swift")

        self.assertEqual(errors, [])


class ReleaseWorkflowTests(unittest.TestCase):
    repository_root = Path(__file__).resolve().parents[1]

    def test_workflow_uses_private_least_privilege_publication(self) -> None:
        workflow = (
            self.repository_root / ".github/workflows/release-packages.yml"
        ).read_text(encoding="utf-8")

        self.assertIn("permissions:\n  contents: read", workflow)
        self.assertIn("packages: write", workflow)
        self.assertEqual(workflow.count("packages: write"), 1)
        self.assertIn("git subtree split --prefix=packages/swift", workflow)
        self.assertIn("git@github.com:qenterra/design-system-swift.git", workflow)
        self.assertIn("QDS_SWIFT_DEPLOY_KEY", workflow)
        self.assertIn("python3 scripts/package_release.py classify-ref", workflow)
        self.assertIn("d23441a48e516b6c34aea4fa41551a30e30af803", workflow)
        self.assertIn("249970729cb0ef3589644e2896645e5dc5ba9c38", workflow)
        self.assertIn("330a01c490aca151604b8cf639adc76d48f6c5d4", workflow)
        self.assertNotIn("--force", workflow)
        self.assertNotIn("visibility public", workflow.lower())
        self.assertNotIn("personal_access_token", workflow.lower())

    def test_workflow_checks_tag_against_canonical_version(self) -> None:
        workflow = (
            self.repository_root / ".github/workflows/release-packages.yml"
        ).read_text(encoding="utf-8")

        self.assertIn('[[ "$GITHUB_REF_NAME" == "$version" ]]', workflow)
        self.assertIn("workflow_dispatch:", workflow)
        self.assertIn("publish:", workflow)
        self.assertEqual(
            (self.repository_root / ".nvmrc").read_text(encoding="utf-8"),
            "22\n",
        )

    def test_preflight_preserves_visual_diagnostics_on_failure(self) -> None:
        workflow = (
            self.repository_root / ".github/workflows/release-packages.yml"
        ).read_text(encoding="utf-8")

        self.assertIn("Upload preflight visual diagnostics", workflow)
        self.assertIn("if: ${{ always() }}", workflow)
        self.assertIn("output/tmp/screenshots-current", workflow)
        self.assertIn("output/reports/browser.json", workflow)
        self.assertIn("output/reports/visual-diff.json", workflow)
        self.assertIn("QDS_SCREENSHOT_PROFILE: github-macos-15-arm64", workflow)


if __name__ == "__main__":
    unittest.main()
