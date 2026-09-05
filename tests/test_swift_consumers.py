from __future__ import annotations

import ctypes
import importlib.util
import os
import signal
import shutil
import subprocess
import tempfile
import time
import unittest
import uuid
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


def executable_path_for_pid(pid: int) -> Path | None:
    libproc = ctypes.CDLL("/usr/lib/libproc.dylib", use_errno=True)
    proc_pidpath = libproc.proc_pidpath
    proc_pidpath.argtypes = [ctypes.c_int, ctypes.c_void_p, ctypes.c_uint32]
    proc_pidpath.restype = ctypes.c_int
    buffer = ctypes.create_string_buffer(4096)
    length = proc_pidpath(pid, buffer, len(buffer))
    if length <= 0:
        return None
    return Path(os.fsdecode(buffer.value)).resolve()


def read_recorded_pid(pid_path: Path) -> int | None:
    if not pid_path.exists():
        return None
    try:
        pid = int(pid_path.read_text(encoding="utf-8").strip())
    except (OSError, ValueError):
        raise AssertionError(f"native interaction host wrote an invalid PID file: {pid_path}")
    if pid <= 0:
        raise AssertionError(f"native interaction host wrote a non-positive PID: {pid}")
    return pid


def terminate_exact_host(pid_path: Path, expected_executable: Path) -> None:
    pid = read_recorded_pid(pid_path)
    if pid is None:
        return

    expected = expected_executable.resolve()
    actual = executable_path_for_pid(pid)
    if actual is None:
        return
    if actual != expected:
        raise AssertionError(
            "refusing to terminate PID "
            f"{pid}: expected {expected}, found {actual}"
        )

    try:
        os.kill(pid, signal.SIGTERM)
    except ProcessLookupError:
        return
    term_deadline = time.monotonic() + 2
    while time.monotonic() < term_deadline:
        actual = executable_path_for_pid(pid)
        if actual is None or actual != expected:
            return
        time.sleep(0.02)

    # Validate identity again immediately before the non-recoverable fallback.
    actual = executable_path_for_pid(pid)
    if actual is None or actual != expected:
        return
    try:
        os.kill(pid, signal.SIGKILL)
    except ProcessLookupError:
        return
    kill_deadline = time.monotonic() + 2
    while time.monotonic() < kill_deadline:
        actual = executable_path_for_pid(pid)
        if actual is None or actual != expected:
            return
        time.sleep(0.02)
    raise AssertionError(f"exact native interaction host PID {pid} survived SIGKILL")


def launch_native_interaction_host(
    application: Path,
    bundled_executable: Path,
    environment: dict[str, str],
    pid_path: Path,
    result_path: Path,
    stdout_path: Path,
    stderr_path: Path,
    *,
    timeout: float,
    extra_arguments: tuple[str, ...] = (),
    ready_result: str | None = None,
) -> subprocess.CompletedProcess:
    command = [
        "open",
        "-W",
        "-n",
        "-o",
        str(stdout_path),
        "--stderr",
        str(stderr_path),
        "-a",
        str(application),
        "--args",
        "--qenterra-pid-path",
        str(pid_path),
        "--qenterra-result-path",
        str(result_path),
        *extra_arguments,
    ]
    launcher = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        env=environment,
    )
    try:
        startup_deadline = time.monotonic() + 10
        while not pid_path.exists() and launcher.poll() is None and time.monotonic() < startup_deadline:
            time.sleep(0.02)

        if not pid_path.exists() and launcher.poll() is None:
            raise AssertionError("native interaction host did not record its PID during startup")

        if pid_path.exists():
            pid = read_recorded_pid(pid_path)
            if pid is not None:
                actual = executable_path_for_pid(pid)
                if actual != bundled_executable.resolve() and launcher.poll() is None:
                    raise AssertionError(
                        f"native interaction host PID {pid} belongs to {actual}, "
                        f"not {bundled_executable.resolve()}"
                    )

        if ready_result is not None:
            ready_deadline = time.monotonic() + 10
            while launcher.poll() is None and time.monotonic() < ready_deadline:
                if result_path.exists() and result_path.read_text(encoding="utf-8") == ready_result:
                    break
                time.sleep(0.02)
            else:
                raise AssertionError(
                    f"native interaction host did not publish expected ready result {ready_result!r}"
                )

        launcher_stdout, launcher_stderr = launcher.communicate(timeout=timeout)
        return subprocess.CompletedProcess(
            command,
            launcher.returncode,
            launcher_stdout,
            launcher_stderr,
        )
    finally:
        try:
            terminate_exact_host(pid_path, bundled_executable)
        finally:
            if launcher.poll() is None:
                launcher.kill()
            launcher.communicate()


class SwiftConsumerTests(unittest.TestCase):
    def test_core_only_consumer_builds_against_copied_public_package(self) -> None:
        self._build_fixture("swift-consumer-core")

    def test_media_consumer_builds_against_copied_public_package(self) -> None:
        self._build_fixture("swift-consumer-media")

    def test_player_family_builds_against_copied_public_package(self) -> None:
        self._build_fixture(
            "swift-consumer-media",
            source="""
import QenTerraMediaComponents

let progress = PlaybackProgressPresentation(
    progress: 0.5,
    leadingText: "1:00",
    trailingText: "2:00",
    accessibilityLabel: "Playback progress",
    isEnabled: true
)
let player = PlayerBarPresentation(
    title: "Public Track",
    subtitle: "Public Artist",
    isPlaying: false,
    isShuffleEnabled: false,
    repeatMode: .off,
    progress: progress,
    volume: 0.5,
    isMuted: false,
    isQueuePresented: false,
    favorite: nil
)
let queue = PlaybackQueueRowPresentation(
    id: "public-queue-item",
    title: "Public Track",
    subtitle: "Public Artist",
    durationText: "2:00",
    isCurrent: false,
    isSelected: true,
    isAvailable: true,
    isDraggable: true,
    accessibilityLabel: "Public Track"
)
let lyric = LyricLinePresentation(
    id: "public-lyric",
    text: "Public lyric",
    isActive: false,
    isSynchronized: true,
    inactiveBlurRadius: 0.45
)
let detail = AudioDetail(id: "codec", label: "Codec", value: "FLAC", order: 0)
print(player.hasCurrentItem, queue.isSelected, lyric.opacity, detail.value)
""",
        )

    def test_media_interaction_host_runs_against_copied_public_package(self) -> None:
        if (
            os.environ.get("CODEX_SANDBOX") == "seatbelt"
            and os.environ.get("QDS_RUN_NATIVE_INTERACTION_HOST") != "1"
        ):
            self.skipTest(
                "Codex seatbelt blocks LaunchServices; rerun with "
                "QDS_RUN_NATIVE_INTERACTION_HOST=1 outside the sandbox"
            )
        with tempfile.TemporaryDirectory(prefix="qenterra-swift-media-interaction-") as directory:
            staging = Path(directory)
            application, bundled_executable, environment = self._prepare_media_interaction_host(staging)
            run_id = uuid.uuid4().hex
            pid_path = staging / f"media-interaction-host-{run_id}.pid"
            result_path = staging / f"media-interaction-host-{run_id}.result"
            stdout_path = staging / f"media-interaction-host-{run_id}.stdout"
            stderr_path = staging / f"media-interaction-host-{run_id}.stderr"
            launch = launch_native_interaction_host(
                application,
                bundled_executable,
                environment,
                pid_path,
                result_path,
                stdout_path,
                stderr_path,
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
            self.assertEqual(
                result_path.read_text(encoding="utf-8") if result_path.exists() else "",
                "OK\n",
                "media interaction host did not publish its successful result",
            )
            recorded_pid = read_recorded_pid(pid_path)
            self.assertIsNotNone(recorded_pid, "media interaction host did not record its PID")
            self.assertNotEqual(
                executable_path_for_pid(recorded_pid),
                bundled_executable.resolve(),
                "successful native interaction host remained alive",
            )

    def test_timed_out_media_interaction_host_is_terminated(self) -> None:
        if (
            os.environ.get("CODEX_SANDBOX") == "seatbelt"
            and os.environ.get("QDS_RUN_NATIVE_INTERACTION_HOST") != "1"
        ):
            self.skipTest(
                "Codex seatbelt blocks LaunchServices; rerun with "
                "QDS_RUN_NATIVE_INTERACTION_HOST=1 outside the sandbox"
            )
        with tempfile.TemporaryDirectory(prefix="qenterra-swift-media-timeout-") as directory:
            staging = Path(directory)
            application, bundled_executable, environment = self._prepare_media_interaction_host(staging)

            run_id = uuid.uuid4().hex
            pid_path = staging / f"media-interaction-host-{run_id}.pid"
            result_path = staging / f"media-interaction-host-{run_id}.result"
            stdout_path = staging / f"media-interaction-host-{run_id}.stdout"
            stderr_path = staging / f"media-interaction-host-{run_id}.stderr"
            with self.assertRaises(subprocess.TimeoutExpired):
                launch_native_interaction_host(
                    application,
                    bundled_executable,
                    environment,
                    pid_path,
                    result_path,
                    stdout_path,
                    stderr_path,
                    timeout=0.1,
                    extra_arguments=("--qenterra-test-hang",),
                    ready_result="HANG_READY\n",
                )
            self.assertEqual(
                result_path.read_text(encoding="utf-8") if result_path.exists() else "",
                "HANG_READY\n",
                "timeout regression host did not reach its explicit hang state",
            )
            pid = read_recorded_pid(pid_path)
            self.assertIsNotNone(pid, "timeout regression host did not record its PID")
            self.assertNotEqual(
                executable_path_for_pid(pid),
                bundled_executable.resolve(),
                "timed-out native interaction host survived after its open launcher was killed",
            )

    def _prepare_media_interaction_host(
        self,
        staging: Path,
    ) -> tuple[Path, Path, dict[str, str]]:
        builder = load_builder()
        fixture = ROOT / "tests/fixtures/swift-media-interaction-host"
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
        return application, bundled_executable, environment

    def _build_fixture(self, fixture_name: str, source: str | None = None) -> None:
        builder = load_builder()
        fixture = ROOT / "tests/fixtures" / fixture_name
        with tempfile.TemporaryDirectory(prefix="qenterra-swift-consumer-") as directory:
            staging = Path(directory)
            consumer = staging / "consumer"
            public = staging / "public"
            shutil.copytree(fixture, consumer)
            if source is not None:
                source_files = list((consumer / "Sources").rglob("*.swift"))
                self.assertEqual(len(source_files), 1, fixture_name)
                source_files[0].write_text(source, encoding="utf-8")
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
