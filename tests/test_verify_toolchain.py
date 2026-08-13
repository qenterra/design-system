from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from scripts.verify import require_swift_testing_macros


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


if __name__ == "__main__":
    unittest.main()
