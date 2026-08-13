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

from audit_release_contract import audit_release_contract  # noqa: E402


def tree_digest(root: Path) -> str:
    digest = hashlib.sha256()
    for path in sorted(item for item in root.rglob("*") if item.is_file()):
        digest.update(path.relative_to(root).as_posix().encode())
        digest.update(path.read_bytes())
    return digest.hexdigest()


class ReleaseContractTests(unittest.TestCase):
    def test_compliant_beta_contract_passes_without_mutation(self) -> None:
        fixture = ROOT / "tests" / "fixtures" / "release-contract-pass"
        before = tree_digest(fixture)

        report = audit_release_contract(fixture)

        self.assertEqual(report["status"], "passed")
        self.assertEqual(report["version"], "0.2.0-beta.1")
        self.assertEqual(report["tag"], "v0.2.0-beta.1")
        self.assertEqual(report["errors"], [])
        self.assertEqual(tree_digest(fixture), before)

    def test_drifted_release_surfaces_fail_together(self) -> None:
        fixture = ROOT / "tests" / "fixtures" / "release-contract-fail"

        report = audit_release_contract(fixture)
        errors = "\n".join(report["errors"])

        self.assertEqual(report["status"], "failed")
        self.assertIn("release.tag", errors)
        self.assertIn("artifacts.installer", errors)
        self.assertIn("ad-hoc signing cannot claim notarization", errors)
        self.assertIn("ad-hoc signing requires Gatekeeper disclosure", errors)

    def test_stable_release_uses_plain_semver_and_no_iteration(self) -> None:
        fixture = ROOT / "tests" / "fixtures" / "release-contract-pass"
        with tempfile.TemporaryDirectory() as directory:
            product = Path(directory) / "product"
            shutil.copytree(fixture, product)
            manifest_path = product / "qds-release.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            manifest["release"] = {
                "marketingVersion": "1.0.0",
                "build": 14,
                "channel": "stable",
                "version": "1.0.0",
                "tag": "v1.0.0",
            }
            manifest["product"]["humanReleaseName"] = "Cadence 1.0.0 (14)"
            manifest["artifacts"] = {
                "installer": "Cadence-1.0.0-arm64.dmg",
                "update": "Cadence-1.0.0-arm64.zip",
                "checksums": "Cadence-1.0.0-SHA256SUMS.txt",
            }
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

            report = audit_release_contract(product)

        self.assertEqual(report["status"], "passed")

    def test_dmg_image_background_requires_exact_standard_scale_pair(self) -> None:
        fixture = ROOT / "tests" / "fixtures" / "release-contract-pass"
        with tempfile.TemporaryDirectory() as directory:
            product = Path(directory) / "product"
            shutil.copytree(fixture, product)
            manifest_path = product / "qds-release.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            manifest["installer"]["background"]["scaleFactors"] = [1]
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

            report = audit_release_contract(product)

        self.assertEqual(report["status"], "failed")
        self.assertIn("installer.background.scaleFactors", "\n".join(report["errors"]))

    def test_cli_refuses_output_inside_product(self) -> None:
        fixture = ROOT / "tests" / "fixtures" / "release-contract-pass"
        output = fixture / "forbidden-report.json"
        result = subprocess.run(
            [
                sys.executable,
                str(ROOT / "scripts" / "audit_release_contract.py"),
                str(fixture),
                "--output",
                str(output),
            ],
            capture_output=True,
            text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main()
