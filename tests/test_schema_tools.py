from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from lib.schema_tools import validate_schema  # noqa: E402


class SchemaToolsTests(unittest.TestCase):
    def validate(self, instance: object, schema: dict[str, object]) -> list[str]:
        return validate_schema(instance, schema, ROOT / "schemas" / "inline-test.json")

    def test_const_is_enforced(self) -> None:
        self.assertEqual([], self.validate("packages", {"const": "packages"}))
        self.assertRegex("\n".join(self.validate("dependencies", {"const": "packages"})), "constant")

    def test_unique_items_is_enforced_for_scalars_and_objects(self) -> None:
        scalar_errors = self.validate(["button", "button"], {"type": "array", "uniqueItems": True})
        object_errors = self.validate([{"id": 1}, {"id": 1}], {"type": "array", "uniqueItems": True})
        self.assertRegex("\n".join(scalar_errors), "unique")
        self.assertRegex("\n".join(object_errors), "unique")

    def test_minimum_is_enforced_without_treating_boolean_as_number(self) -> None:
        self.assertEqual([], self.validate(0, {"type": "integer", "minimum": 0}))
        self.assertRegex("\n".join(self.validate(-1, {"type": "integer", "minimum": 0})), "at least")
        self.assertRegex("\n".join(self.validate(True, {"type": "integer", "minimum": 0})), "expected integer")


if __name__ == "__main__":
    unittest.main()
