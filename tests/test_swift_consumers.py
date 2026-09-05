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

    def test_media_interaction_host_runs_against_copied_public_package(self) -> None:
        if (
            os.environ.get("CODEX_SANDBOX") == "seatbelt"
            and os.environ.get("QDS_RUN_NATIVE_INTERACTION_HOST") != "1"
        ):
            self.skipTest(
                "Codex seatbelt blocks LaunchServices; rerun with "
                "QDS_RUN_NATIVE_INTERACTION_HOST=1 outside the sandbox"
            )
        builder = load_builder()
        fixture = ROOT / "tests/fixtures/swift-media-interaction-host"
        with tempfile.TemporaryDirectory(prefix="qenterra-swift-media-interaction-") as directory:
            staging = Path(directory)
            consumer = staging / "consumer"
            public = staging / "public"
            shutil.copytree(fixture, consumer)
            builder.export_public_tree(public, ROOT)
            environment = os.environ.copy()
            environment["SWIFTPM_DISABLE_SANDBOX"] = "1"
            scratch = staging / "scratch"
            build = subprocess.run(
                [
                    "swift",
                    "build",
                    "--package-path",
                    str(consumer),
                    "--scratch-path",
                    str(scratch),
                    "--disable-sandbox",
                ],
                capture_output=True,
                text=True,
                env=environment,
                check=False,
            )
            self.assertEqual(
                build.returncode,
                0,
                f"media interaction host failed to build:\n{build.stdout}\n{build.stderr}",
            )
            executable = scratch / "debug/QenTerraMediaInteractionHost"
            application = staging / "QenTerraMediaInteractionHost.app"
            bundled_executable = application / "Contents/MacOS/QenTerraMediaInteractionHost"
            bundled_executable.parent.mkdir(parents=True)
            shutil.copy2(executable, bundled_executable)
            bundled_executable.chmod(0o755)
            shutil.copy2(fixture / "Info.plist", application / "Contents/Info.plist")
            sign = subprocess.run(
                ["codesign", "--force", "--sign", "-", str(application)],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(
                sign.returncode,
                0,
                f"media interaction host failed ad-hoc signing:\n{sign.stdout}\n{sign.stderr}",
            )
            stdout_path = staging / "media-interaction-host.stdout"
            stderr_path = staging / "media-interaction-host.stderr"
            launch = subprocess.run(
                [
                    "open",
                    "-W",
                    "-n",
                    "-o",
                    str(stdout_path),
                    "--stderr",
                    str(stderr_path),
                    "-a",
                    str(application),
                ],
                capture_output=True,
                text=True,
                env=environment,
                check=False,
                timeout=30,
            )
            host_stdout = stdout_path.read_text(encoding="utf-8") if stdout_path.exists() else ""
            host_stderr = stderr_path.read_text(encoding="utf-8") if stderr_path.exists() else ""
            bundle_inventory = [
                f"{path.relative_to(application)} mode={oct(path.stat().st_mode)} size={path.stat().st_size}"
                for path in application.rglob("*")
            ]
            self.assertEqual(
                launch.returncode,
                0,
                "media interaction host failed to launch:\n"
                f"{launch.stdout}\n{launch.stderr}\n{host_stdout}\n{host_stderr}\n{bundle_inventory}",
            )
            self.assertIn(
                "MEDIA_INTERACTION_HOST_OK",
                host_stdout,
                f"media interaction host failed:\n{host_stdout}\n{host_stderr}",
            )

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
