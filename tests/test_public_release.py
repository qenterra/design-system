from __future__ import annotations

import hashlib
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BUILDER = ROOT / "scripts/build_public_packages.py"
BOUNDARY = ROOT / "scripts/verify_public_boundary.py"


def load_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise AssertionError(f"cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class PublicReleaseContractTests(unittest.TestCase):
    def test_release_tools_exist(self) -> None:
        self.assertTrue(BUILDER.is_file(), "public release builder is missing")
        self.assertTrue(BOUNDARY.is_file(), "public boundary verifier is missing")

    def test_manifest_matches_registered_public_files(self) -> None:
        self.assertTrue(BUILDER.is_file(), "public release builder is missing")
        builder = load_module(BUILDER, "public_builder")
        expected = builder.build_manifest(ROOT)
        actual = json.loads(
            (ROOT / "packages/release-manifest.json").read_text(encoding="utf-8")
        )
        self.assertEqual(actual, expected)
        self.assertNotIn("sourceSha", actual)
        self.assertNotIn("commit", json.dumps(actual).lower())

    def test_boundary_detects_an_undeclared_file(self) -> None:
        self.assertTrue(BOUNDARY.is_file(), "public boundary verifier is missing")
        boundary = load_module(BOUNDARY, "public_boundary")
        with tempfile.TemporaryDirectory() as directory:
            public = Path(directory)
            (public / "README.md").write_text("public\n", encoding="utf-8")
            content = b"public\n"
            manifest = {
                "schemaVersion": 1,
                "version": "5.0.0",
                "repository": "https://github.com/qenterra/packages",
                "files": [
                    {
                        "path": "README.md",
                        "sha256": hashlib.sha256(content).hexdigest(),
                        "bytes": len(content),
                    }
                ],
            }
            (public / "release-manifest.json").write_text(
                json.dumps(manifest), encoding="utf-8"
            )
            (public / "private.txt").write_text("should not ship\n", encoding="utf-8")
            errors = boundary.validate_public_tree(public)
            self.assertIn("undeclared public file: private.txt", errors)

    def test_boundary_detects_private_markers(self) -> None:
        self.assertTrue(BOUNDARY.is_file(), "public boundary verifier is missing")
        boundary = load_module(BOUNDARY, "public_boundary_markers")
        with tempfile.TemporaryDirectory() as directory:
            public = Path(directory)
            content = b"/Users/example/private\n"
            (public / "README.md").write_bytes(content)
            (public / "release-manifest.json").write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "version": "5.0.0",
                        "repository": "https://github.com/qenterra/packages",
                        "files": [
                            {
                                "path": "README.md",
                                "sha256": hashlib.sha256(content).hexdigest(),
                                "bytes": len(content),
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            errors = boundary.validate_public_tree(public)
            self.assertIn("README.md: contains an absolute local path", errors)

    def test_boundary_detects_ignored_cache_content(self) -> None:
        self.assertTrue(BOUNDARY.is_file(), "public boundary verifier is missing")
        boundary = load_module(BOUNDARY, "public_boundary_cache")
        with tempfile.TemporaryDirectory() as directory:
            public = Path(directory)
            content = b"public\n"
            (public / "README.md").write_bytes(content)
            (public / "release-manifest.json").write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "version": "5.0.0",
                        "repository": "https://github.com/qenterra/packages",
                        "files": [
                            {
                                "path": "README.md",
                                "sha256": hashlib.sha256(content).hexdigest(),
                                "bytes": len(content),
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            cache = public / "node_modules/example"
            cache.mkdir(parents=True)
            (cache / "cache.js").write_text("cache\n", encoding="utf-8")
            errors = boundary.validate_public_tree(public)
            self.assertIn("undeclared public file: node_modules/example/cache.js", errors)


if __name__ == "__main__":
    unittest.main()
