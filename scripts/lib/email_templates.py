"""Validation helpers for the human-operated QenTerra email template registry."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any, Optional
from urllib.parse import urlparse

from lib.schema_tools import validate_schema


VARIABLE = re.compile(r"\{\{([a-z][a-zA-Z0-9]*)\}\}")
IDENTIFIER = re.compile(r"^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$")
FIELD_IDENTIFIER = re.compile(r"^[a-z][a-zA-Z0-9]*$")
ALLOWED_CATEGORIES = {"contact", "support", "account", "operation", "payment"}
EXPECTED_CATEGORY_COUNTS = {"contact": 9, "support": 16, "account": 12, "operation": 8, "payment": 3}
CHANNEL_BY_CATEGORY = {
    "contact": "contact",
    "support": "support",
    "account": "support",
    "operation": "support",
    "payment": "support",
}
PROHIBITED_KEYS = {
    "endpoint",
    "image",
    "persistence",
    "remoteImage",
    "sendEndpoint",
    "tracking",
    "trackingPixel",
    "unsubscribe",
}


def load_email_registry(root: Path) -> dict[str, Any]:
    """Load the canonical email registry without mutating it."""
    path = root / "registry" / "email-templates.json"
    return json.loads(path.read_text(encoding="utf-8"))


def variables_in(value: Any) -> set[str]:
    if isinstance(value, str):
        return set(VARIABLE.findall(value))
    if isinstance(value, list):
        result: set[str] = set()
        for item in value:
            result.update(variables_in(item))
        return result
    if isinstance(value, dict):
        result = set()
        for item in value.values():
            result.update(variables_in(item))
        return result
    return set()


def conditions_in(value: Any) -> set[str]:
    result: set[str] = set()
    if isinstance(value, list):
        for item in value:
            result.update(conditions_in(item))
    elif isinstance(value, dict):
        condition = value.get("condition")
        if isinstance(condition, str):
            result.add(condition)
        for item in value.values():
            result.update(conditions_in(item))
    return result


def prohibited_keys_in(value: Any, location: str = "$") -> list[str]:
    errors: list[str] = []
    if isinstance(value, dict):
        for key, child in value.items():
            child_location = f"{location}.{key}"
            if key in PROHIBITED_KEYS:
                errors.append(f"{child_location}: prohibited capability key")
            errors.extend(prohibited_keys_in(child, child_location))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            errors.extend(prohibited_keys_in(child, f"{location}[{index}]"))
    return errors


def is_https(value: str) -> bool:
    parsed = urlparse(value)
    return parsed.scheme == "https" and bool(parsed.netloc)


def validate_email_data(
    data: dict[str, Any],
    version: str,
    channels: dict[str, str],
    expected_count: Optional[int] = None,
) -> list[str]:
    """Validate semantic invariants that JSON Schema cannot express."""
    errors = prohibited_keys_in(data)

    if data.get("version") != version:
        errors.append(f"version {data.get('version')!r} does not match VERSION {version}")

    capabilities = data.get("capabilities", {})
    for name in ("sendsEmail", "persistsInput", "externalRequests", "marketing"):
        if capabilities.get(name) is not False:
            errors.append(f"capabilities.{name} must remain false")

    fields = data.get("fields", [])
    field_by_id: dict[str, dict[str, Any]] = {}
    for index, field in enumerate(fields if isinstance(fields, list) else []):
        if not isinstance(field, dict):
            continue
        identifier = field.get("id")
        if not isinstance(identifier, str) or not FIELD_IDENTIFIER.fullmatch(identifier):
            errors.append(f"fields[{index}]: invalid field id {identifier!r}")
            continue
        if identifier in field_by_id:
            errors.append(f"duplicate field id {identifier!r}")
        field_by_id[identifier] = field
        locales = field.get("locales", {})
        if set(locales) != {"en", "ru"}:
            errors.append(f"field {identifier!r}: locales must be exactly en and ru")
        if field.get("type") == "url":
            for locale in ("en", "ru"):
                example = locales.get(locale, {}).get("example", "")
                if not isinstance(example, str) or not is_https(example):
                    errors.append(f"field {identifier!r}/{locale}: URL field requires an HTTPS example")

    templates = data.get("templates", [])
    if expected_count is not None and len(templates) != expected_count:
        errors.append(f"expected {expected_count} email templates, found {len(templates)}")

    template_ids: set[str] = set()
    category_counts = {category: 0 for category in ALLOWED_CATEGORIES}
    for index, template in enumerate(templates if isinstance(templates, list) else []):
        if not isinstance(template, dict):
            continue
        identifier = template.get("id")
        location = f"templates[{index}]"
        if not isinstance(identifier, str) or not IDENTIFIER.fullmatch(identifier):
            errors.append(f"{location}: invalid template id {identifier!r}")
            identifier = str(identifier)
        if identifier in template_ids:
            errors.append(f"duplicate template id {identifier!r}")
        template_ids.add(identifier)

        category = template.get("category")
        if category not in ALLOWED_CATEGORIES:
            errors.append(f"{identifier}: unsupported category {category!r}")
        else:
            category_counts[category] += 1
            expected_channel = CHANNEL_BY_CATEGORY[category]
            if template.get("channel") != expected_channel:
                errors.append(f"{identifier}: category {category!r} must use channel {expected_channel!r}")

        channel = template.get("channel")
        if channel not in channels:
            errors.append(f"{identifier}: unknown contact channel {channel!r}")

        field_references = template.get("fields", [])
        declared: set[str] = set()
        for reference in field_references if isinstance(field_references, list) else []:
            if not isinstance(reference, dict):
                continue
            field_id = reference.get("id")
            if field_id in declared:
                errors.append(f"{identifier}: duplicate field reference {field_id!r}")
            declared.add(field_id)
            if field_id not in field_by_id:
                errors.append(f"{identifier}: unknown field reference {field_id!r}")

        locales = template.get("locales", {})
        if set(locales) != {"en", "ru"}:
            errors.append(f"{identifier}: locales must be exactly en and ru")
            continue
        english = locales.get("en", {})
        russian = locales.get("ru", {})
        english_variables = variables_in(english)
        russian_variables = variables_in(russian)
        used = english_variables | russian_variables
        unknown = used - declared
        if unknown:
            errors.append(f"{identifier}: undeclared variable(s) {sorted(unknown)!r}")
        conditions = conditions_in(locales)
        unknown_conditions = conditions - declared
        if unknown_conditions:
            errors.append(f"{identifier}: condition uses undeclared field(s) {sorted(unknown_conditions)!r}")
        unused = declared - used - conditions
        if unused:
            errors.append(f"{identifier}: field(s) declared but unused {sorted(unused)!r}")
        if english_variables != russian_variables:
            errors.append(f"{identifier}: locale variable sets differ")
        optional_sections = {"callout", "cta"}
        if ({key for key in english if key in optional_sections} != {key for key in russian if key in optional_sections}):
            errors.append(f"{identifier}: optional locale sections differ")

    if expected_count == 48 and category_counts != EXPECTED_CATEGORY_COUNTS:
        errors.append(f"email template category counts differ: {category_counts!r}")
    return errors


def validate_email_registry(root: Path, version: str) -> list[str]:
    """Validate the canonical registry, its schema, contact roles, and fixed catalogue."""
    path = root / "registry" / "email-templates.json"
    if not path.is_file():
        return ["registry/email-templates.json: missing canonical email templates"]
    try:
        data = load_email_registry(root)
    except (OSError, json.JSONDecodeError) as error:
        return [f"registry/email-templates.json: {error}"]

    schema_reference = data.get("$schema", "")
    schema_path = (path.parent / schema_reference).resolve()
    if not schema_reference or not schema_path.is_file():
        return ["registry/email-templates.json:$schema: missing schema"]
    try:
        schema = json.loads(schema_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"schemas/email-templates.schema.json: {error}"]

    errors = [
        f"registry/email-templates.json:{error}"
        for error in validate_schema(data, schema, schema_path)
    ]

    contact_path = root / "registry" / "contact-channels.json"
    if not contact_path.is_file():
        return errors + ["registry/contact-channels.json: required by email templates"]
    contact_data = json.loads(contact_path.read_text(encoding="utf-8"))
    channels = {
        channel.get("id"): channel.get("address")
        for channel in contact_data.get("channels", [])
        if isinstance(channel, dict) and isinstance(channel.get("id"), str)
    }
    errors.extend(
        f"registry/email-templates.json:{error}"
        for error in validate_email_data(data, version, channels, expected_count=48)
    )
    return errors
