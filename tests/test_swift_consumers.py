from __future__ import annotations

import importlib.util
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BUILDER = ROOT / "scripts/build_public_packages.py"


def load_builder():
    spec = importlib.util.spec_from_file_location("public_package_builder", BUILDER)
    if spec is None or spec.loader is None:
        raise AssertionError("cannot load public package builder")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class SwiftConsumerTests(unittest.TestCase):
    def test_core_only_consumer_builds_against_copied_public_package(self) -> None:
        self._build_fixture("swift-consumer-core")

    def test_media_consumer_builds_against_copied_public_package(self) -> None:
        self._build_fixture("swift-consumer-media")

    def _build_fixture(self, fixture_name: str) -> None:
        builder = load_builder()
        fixture = ROOT / "tests/fixtures" / fixture_name
        with tempfile.TemporaryDirectory(prefix="qenterra-swift-consumer-") as directory:
            staging = Path(directory)
            consumer = staging / "consumer"
            public = staging / "public"
            shutil.copytree(fixture, consumer)
            builder.export_public_tree(public, ROOT)
            environment = os.environ.copy()
            environment["SWIFTPM_DISABLE_SANDBOX"] = "1"
            result = subprocess.run(
                ["swift", "build", "--package-path", str(consumer), "--scratch-path", str(staging / "scratch"), "--disable-sandbox"],
                capture_output=True,
                text=True,
                env=environment,
                check=False,
            )
            self.assertEqual(
                result.returncode,
                0,
                f"{fixture_name} failed to build against copied public package:\n{result.stdout}\n{result.stderr}",
            )
