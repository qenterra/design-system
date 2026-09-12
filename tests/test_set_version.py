from __future__ import annotations

import hashlib
import importlib.util
import json
import shutil
import subprocess
import tempfile
import unittest
from contextlib import contextmanager
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
SET_VERSION = ROOT / "scripts/set_version.py"


def load_set_version():
    spec = importlib.util.spec_from_file_location("set_version", SET_VERSION)
    if spec is None or spec.loader is None:
        raise AssertionError("cannot load set_version.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


@contextmanager
def copied_repository():
    with tempfile.TemporaryDirectory(prefix="qenterra-version-copy-") as directory:
        destination = Path(directory) / "design-system"
        shutil.copytree(
            ROOT,
            destination,
            ignore=shutil.ignore_patterns(".git", ".build", ".swiftpm", "__pycache__"),
        )
        yield destination.resolve()


SOURCE_CATALOGS = (
    "ExploreSwiftUI", "MagicUI", "ShadcnUI", "UIable", "ReUI",
    "BootstrapIcons", "Iconoir", "PhosphorIcons", "TablerIcons",
)


def next_version(root: Path) -> str:
    current = (root / "VERSION").read_text(encoding="utf-8").strip()
    return f"{int(current.split('.')[0]) + 1}.0.0"


def catalog_payload_hashes(root: Path) -> dict[str, str]:
    return {
        path.relative_to(root).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
        for directory in SOURCE_CATALOGS
        for path in (root / "packages/Sources" / directory).rglob("*")
        if path.is_file() and path.name != "manifest.json"
    }


def file_hashes(root: Path) -> dict[str, str]:
    return {
        path.relative_to(root).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in root.rglob("*")
        if path.is_file()
    }


class SetVersionTests(unittest.TestCase):
    def test_set_version_updates_every_canonical_version_surface_and_regenerates_outputs(self) -> None:
        module = load_set_version()
        with copied_repository() as root:
            target = next_version(root)
            before_payloads = catalog_payload_hashes(root)
            before_manifests = {
                directory: json.loads((root / "packages/Sources" / directory / "manifest.json").read_text(encoding="utf-8"))
                for directory in SOURCE_CATALOGS
            }
            changed = {path.relative_to(root).as_posix() for path in module.set_version(root, target)}

            self.assertEqual((root / "VERSION").read_text(encoding="utf-8"), f"{target}\n")
            for path in sorted((root / "tokens").glob("*.json")):
                self.assertEqual(json.loads(path.read_text(encoding="utf-8"))["meta"]["version"], target, path.name)
            for path in sorted((root / "registry").glob("*.json")):
                self.assertEqual(json.loads(path.read_text(encoding="utf-8"))["version"], target, path.name)

            package_registry = json.loads((root / "registry/packages.json").read_text(encoding="utf-8"))
            self.assertTrue(package_registry["packages"])
            self.assertEqual({item["version"] for item in package_registry["packages"]}, {target})
            for relative in ("package.json", "packages/package.json", "packages/npm/design-tokens/package.json"):
                self.assertEqual(json.loads((root / relative).read_text(encoding="utf-8"))["version"], target)
            for relative in (
                "packages/Sources/QenTerra/manifest.json",
                "registry/published-artifacts.json",
                "packages/release-manifest.json",
            ):
                self.assertEqual(json.loads((root / relative).read_text(encoding="utf-8"))["version"], target)

            for directory, previous in before_manifests.items():
                relative = f"packages/Sources/{directory}/manifest.json"
                current = json.loads((root / relative).read_text(encoding="utf-8"))
                self.assertEqual(current, {**previous, "version": target}, relative)
                self.assertIn(relative, changed)
            self.assertEqual(catalog_payload_hashes(root), before_payloads)

            self.assertIn("VERSION", changed)
            self.assertIn("packages/Sources/QenTerra/DesignTokens/GeneratedTokens.swift", changed)
            self.assertIn("registry/published-artifacts.json", changed)
            self.assertIn("packages/release-manifest.json", changed)
            self.assertFalse(module.generate_module.check_outputs(root))
            self.assertFalse(module.public_module.check_manifest(root))

    def test_set_version_rejects_prerelease_and_leaves_copy_unchanged(self) -> None:
        module = load_set_version()
        with copied_repository() as root:
            before = file_hashes(root)
            for invalid in ("2.0.0-rc.1", "2.0.0+build", "02.0.0", "2.0", "v2.0.0"):
                with self.subTest(version=invalid), self.assertRaisesRegex(ValueError, "plain SemVer"):
                    module.set_version(root, invalid)
            self.assertEqual(file_hashes(root), before)

    def test_set_version_fails_before_writes_when_a_canonical_surface_is_invalid(self) -> None:
        module = load_set_version()
        with copied_repository() as root:
            target = next_version(root)
            token = root / "tokens/semantic.json"
            data = json.loads(token.read_text(encoding="utf-8"))
            del data["meta"]["version"]
            token.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
            before = file_hashes(root)
            with self.assertRaisesRegex(ValueError, "tokens/semantic.json"):
                module.set_version(root, target)
            self.assertEqual(file_hashes(root), before)

    def test_set_version_rolls_back_if_applying_the_transaction_fails(self) -> None:
        module = load_set_version()
        with copied_repository() as root:
            target = next_version(root)
            before = file_hashes(root)
            original_replace = module.os.replace
            root_writes = 0

            def fail_second_root_replace(source: Path, destination: Path) -> None:
                nonlocal root_writes
                destination = Path(destination).resolve()
                if root == destination or root in destination.parents:
                    root_writes += 1
                    if root_writes == 2:
                        raise OSError("synthetic transaction failure")
                original_replace(source, destination)

            with mock.patch.object(module.os, "replace", side_effect=fail_second_root_replace):
                with self.assertRaisesRegex(OSError, "synthetic transaction failure"):
                    module.set_version(root, target)
            self.assertEqual(file_hashes(root), before)

    def test_command_prints_changed_paths_without_changing_repository_history(self) -> None:
        with copied_repository() as root:
            target = next_version(root)
            subprocess.run(["git", "init", "-q"], cwd=root, check=True)
            subprocess.run(["git", "add", "."], cwd=root, check=True)
            subprocess.run(
                ["git", "-c", "user.name=Version Test", "-c", "user.email=version@example.invalid", "commit", "-qm", "fixture"],
                cwd=root,
                check=True,
            )
            before_head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
            result = subprocess.run(
                ["python3", "scripts/set_version.py", target, "--root", str(root)],
                cwd=root,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(), before_head)
            printed = set(result.stdout.splitlines())
            self.assertIn("VERSION", printed)
            self.assertIn("packages/release-manifest.json", printed)


if __name__ == "__main__":
    unittest.main()
