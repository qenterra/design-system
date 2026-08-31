from __future__ import annotations

import os
import sys
import tempfile
import unittest
from pathlib import Path

from scripts.verify import require_swift_testing_macros, run


class SwiftToolchainPreflightTests(unittest.TestCase):
    def test_requires_full_xcode_testing_macros_before_swift_commands(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            developer_dir = Path(temporary_directory) / "CommandLineTools"

            with self.assertRaisesRegex(RuntimeError, "full Xcode.*TestingMacros"):
                require_swift_testing_macros(developer_dir)

            macro = (
                developer_dir
                / "Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing"
                / "libTestingMacros.dylib"
            )
            macro.parent.mkdir(parents=True)
            macro.touch()

            self.assertIsNone(require_swift_testing_macros(developer_dir))


class VerificationProcessIsolationTests(unittest.TestCase):
    def test_python_child_does_not_write_bytecode_into_worktree(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            (root / "fixture_module.py").write_text("VALUE = 1\n", encoding="utf-8")
            environment = os.environ.copy()
            environment.pop("PYTHONDONTWRITEBYTECODE", None)
            environment.pop("PYTHONPYCACHEPREFIX", None)
            homebrew_python = Path("/opt/homebrew/bin/python3")
            python = homebrew_python if homebrew_python.is_file() else Path(sys.executable)

            run(
                [str(python), "-c", "import fixture_module"],
                env=environment,
                cwd=root,
            )

            self.assertFalse((root / "__pycache__").exists())


if __name__ == "__main__":
    unittest.main()
