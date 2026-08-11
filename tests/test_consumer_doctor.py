from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
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

    def test_expired_exception_fails_the_doctor(self) -> None:
        fixture = ROOT / "tests" / "fixtures" / "consumer-pass"
        with tempfile.TemporaryDirectory() as directory:
            consumer = Path(directory) / "consumer"
            shutil.copytree(fixture, consumer)
            exceptions_path = consumer / "qds-exceptions.json"
            exceptions = json.loads(exceptions_path.read_text(encoding="utf-8"))
            exceptions["exceptions"] = [
                {
                    "id": "expired-example",
                    "rule": "raw-color",
                    "path": "Sources/App.swift",
                    "reason": "A test-only exception verifies expiry enforcement.",
                    "owner": "QDS tests",
                    "reviewTrigger": "Review whenever the fixture changes.",
                    "reviewBy": "2000-01-01",
                }
            ]
            exceptions_path.write_text(
                json.dumps(exceptions),
                encoding="utf-8"
            )

            report = audit_consumer(consumer)

        self.assertEqual(report["status"], "failed")
        self.assertIn("expired-example", " ".join(report["errors"]))

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
