from __future__ import annotations

import hashlib
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from audit_consumer import audit_consumer  # noqa: E402


def tree_digest(root: Path) -> str:
    digest = hashlib.sha256()
    for path in sorted(item for item in root.rglob("*") if item.is_file()):
        digest.update(path.relative_to(root).as_posix().encode())
        digest.update(path.read_bytes())
    return digest.hexdigest()


class ConsumerDoctorTests(unittest.TestCase):
    def test_compliant_fixture_passes_without_mutation(self) -> None:
        fixture = ROOT / "tests" / "fixtures" / "consumer-pass"
        before = tree_digest(fixture)
        report = audit_consumer(fixture)
        self.assertEqual(report["status"], "passed")
        self.assertEqual(report["findings"], [])
        self.assertEqual(tree_digest(fixture), before)

    def test_noncompliant_fixture_reports_raw_color_and_missing_adapter(self) -> None:
        fixture = ROOT / "tests" / "fixtures" / "consumer-fail"
        report = audit_consumer(fixture)
        rules = {finding["rule"] for finding in report["findings"]}
        self.assertEqual(report["status"], "failed")
        self.assertEqual(rules, {"raw-color", "missing-css-adapter"})

    def test_swift_fixture_reports_raw_semantic_values(self) -> None:
        fixture = ROOT / "tests" / "fixtures" / "consumer-swift-fail"
        report = audit_consumer(fixture)
        rules = {finding["rule"] for finding in report["findings"]}
        self.assertEqual(report["status"], "failed")
        self.assertEqual(rules, {"raw-color", "raw-duration", "raw-radius"})

    def test_cli_refuses_output_inside_consumer(self) -> None:
        fixture = ROOT / "tests" / "fixtures" / "consumer-pass"
        output = fixture / "forbidden-report.json"
        result = subprocess.run(
            [sys.executable, str(ROOT / "scripts" / "audit_consumer.py"), str(fixture), "--output", str(output)],
            capture_output=True,
            text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main()
