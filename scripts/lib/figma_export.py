"""Deterministic, import-friendly Figma payloads derived from Design System sources."""

from __future__ import annotations

from typing import Any

from lib.token_tools import flatten, resolve


def generate_figma_exports(
    tokens: dict[str, dict[str, Any]],
    components: dict[str, Any],
    icons: dict[str, Any],
) -> dict[str, dict[str, Any]]:
    foundation = tokens["foundation"]
    semantic = tokens["semantic"]
    primitive_variables = []
    for name, value in sorted(
        flatten({key: foundation[key] for key in ("color", "space", "radius", "stroke", "opacity", "size")}).items()
    ):
        primitive_variables.append(
            {
                "name": name.replace(".", "/"),
                "type": "COLOR" if isinstance(value, str) and value.startswith("#") else "FLOAT",
                "valuesByMode": {"Default": value},
            }
        )

    semantic_variables = []
    light = flatten(semantic["modes"]["light"])
    dark = flatten(semantic["modes"]["dark"])
    for name in sorted(light):
        semantic_variables.append(
            {
                "name": name.replace(".", "/"),
                "type": "COLOR",
                "valuesByMode": {
                    "Light": resolve(light[name], foundation),
                    "Dark": resolve(dark[name], foundation),
                },
            }
        )

    typography = []
    for name, role in tokens["typography"]["roles"].items():
        typography.append(
            {
                "name": name,
                "fontFamily": tokens["typography"]["family"][role.get("family", "sans")],
                "fontSize": role["size"],
                "lineHeight": role["line"],
                "fontWeight": role["weight"],
                "letterSpacing": role["tracking"],
            }
        )

    version = tokens["foundation"]["meta"]["version"]
    return {
        "variables.json": {
            "format": "design-system-figma-variables-v1",
            "version": version,
            "collections": [
                {"name": "Design System Foundation", "modes": ["Default"], "variables": primitive_variables},
                {"name": "Design System Semantic", "modes": ["Light", "Dark"], "variables": semantic_variables},
            ],
        },
        "styles.json": {"format": "design-system-figma-styles-v1", "version": version, "textStyles": typography},
        "components.json": {
            "format": "design-system-figma-components-v1",
            "version": version,
            "components": components["components"],
        },
        "icons.json": {
            "format": "design-system-figma-sf-symbols-v2",
            "version": version,
            "platform": icons["platform"],
            "icons": icons["icons"],
        },
    }
