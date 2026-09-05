"""Small fail-closed JSON Schema subset used by local Design System validators."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any


JSON_TYPES = {
    "object": dict,
    "array": list,
    "string": str,
    "number": (int, float),
    "integer": int,
    "boolean": bool,
}


def _resolve_fragment(document: Any, fragment: str) -> Any:
    current = document
    if not fragment:
        return current
    if not fragment.startswith("/"):
        raise ValueError(f"Unsupported schema fragment #{fragment}")
    for segment in fragment[1:].split("/"):
        key = segment.replace("~1", "/").replace("~0", "~")
        current = current[key]
    return current


def _load_reference(reference: str, schema_path: Path, root_schema: dict[str, Any]) -> tuple[dict[str, Any], Path, dict[str, Any]]:
    file_part, _, fragment = reference.partition("#")
    if file_part:
        target_path = (schema_path.parent / file_part).resolve()
        target_root = json.loads(target_path.read_text(encoding="utf-8"))
    else:
        target_path = schema_path
        target_root = root_schema
    return _resolve_fragment(target_root, fragment), target_path, target_root


def validate_schema(instance: Any, schema: dict[str, Any], schema_path: Path, location: str = "") -> list[str]:
    """Validate the subset Design System schemas use; unsupported keywords fail loudly."""
    root_schema = schema

    def walk(value: Any, rule: dict[str, Any], path: str, current_path: Path, current_root: dict[str, Any]) -> list[str]:
        errors: list[str] = []
        if "$ref" in rule:
            referenced, ref_path, ref_root = _load_reference(rule["$ref"], current_path, current_root)
            return walk(value, referenced, path, ref_path, ref_root)

        for branch in rule.get("allOf", []):
            errors.extend(walk(value, branch, path, current_path, current_root))

        if "if" in rule:
            condition_matches = not walk(
                value,
                rule["if"],
                path,
                current_path,
                current_root,
            )
            selected_branch = "then" if condition_matches else "else"
            if selected_branch in rule:
                errors.extend(
                    walk(
                        value,
                        rule[selected_branch],
                        path,
                        current_path,
                        current_root,
                    )
                )

        expected = rule.get("type")
        if expected:
            expected_types = expected if isinstance(expected, list) else [expected]
            matches = False
            for type_name in expected_types:
                python_type = JSON_TYPES[type_name]
                if type_name in {"number", "integer"} and isinstance(value, bool):
                    continue
                if isinstance(value, python_type):
                    matches = True
                    break
            if not matches:
                return [f"{path or '$'}: expected {' or '.join(expected_types)}, got {type(value).__name__}"]

        if "enum" in rule and value not in rule["enum"]:
            errors.append(f"{path or '$'}: expected one of {rule['enum']!r}, got {value!r}")

        if "const" in rule and value != rule["const"]:
            errors.append(f"{path or '$'}: expected constant {rule['const']!r}, got {value!r}")

        if (
            "minimum" in rule
            and isinstance(value, (int, float))
            and not isinstance(value, bool)
            and value < rule["minimum"]
        ):
            errors.append(f"{path or '$'}: expected a value of at least {rule['minimum']}")

        if isinstance(value, str):
            if len(value) < rule.get("minLength", 0):
                errors.append(f"{path or '$'}: string is shorter than {rule['minLength']}")
            if "pattern" in rule and not re.fullmatch(rule["pattern"], value):
                errors.append(f"{path or '$'}: value does not match {rule['pattern']!r}")

        if isinstance(value, list):
            if len(value) < rule.get("minItems", 0):
                errors.append(f"{path or '$'}: expected at least {rule['minItems']} items")
            if "maxItems" in rule and len(value) > rule["maxItems"]:
                errors.append(f"{path or '$'}: expected at most {rule['maxItems']} items")
            if rule.get("uniqueItems"):
                canonical = [
                    json.dumps(item, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
                    for item in value
                ]
                if len(canonical) != len(set(canonical)):
                    errors.append(f"{path or '$'}: array items must be unique")
            item_rule = rule.get("items")
            if item_rule:
                for index, item in enumerate(value):
                    errors.extend(walk(item, item_rule, f"{path}[{index}]", current_path, current_root))

        if isinstance(value, dict):
            for required in rule.get("required", []):
                if required not in value:
                    errors.append(f"{path or '$'}: missing required property {required!r}")
            properties = rule.get("properties", {})
            additional = rule.get("additionalProperties", True)
            for key, child in value.items():
                child_path = f"{path}.{key}" if path else key
                if key in properties:
                    errors.extend(walk(child, properties[key], child_path, current_path, current_root))
                elif additional is False:
                    errors.append(f"{child_path}: additional property is not allowed")
                elif isinstance(additional, dict):
                    errors.extend(walk(child, additional, child_path, current_path, current_root))
        return errors

    return walk(instance, schema, location, schema_path, root_schema)
