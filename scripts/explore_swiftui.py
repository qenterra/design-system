#!/usr/bin/env python3
"""Synchronize and verify the exact Explore SwiftUI source catalog."""

from __future__ import annotations

import argparse
import concurrent.futures
import dataclasses
import hashlib
import html.parser
import json
import re
import shutil
import subprocess
import sys
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]
SITE_URL = "https://exploreswiftui.com/"
SITEMAP_URL = f"{SITE_URL}sitemap.xml"
PUBLIC_MANIFEST = Path("packages/Sources/ExploreSwiftUI/manifest.json")
PRIVATE_REGISTRY = Path("registry/native-patterns.json")
COMPONENT_ROOT = Path("packages/Sources/ExploreSwiftUI/Components")
USER_AGENT = "QenTerra-Design-System-Source-Sync/1.0"
PLATFORMS = ("iOS", "iPadOS", "macOS", "watchOS", "tvOS", "visionOS")


@dataclasses.dataclass(frozen=True)
class NativePattern:
    identifier: str
    name: str
    category: str
    filename: str
    url: str
    description: str
    apple_documentation_url: str
    programming_language: str
    runtime_platform: str
    published_at: str
    updated_at: str
    tags: tuple[str, ...]
    platforms: dict[str, str]
    source: str

    @property
    def source_bytes(self) -> bytes:
        return self.source.encode("utf-8")

    @property
    def sha256(self) -> str:
        return hashlib.sha256(self.source_bytes).hexdigest()

    @property
    def source_path(self) -> str:
        return f"Sources/ExploreSwiftUI/Components/{self.category}/{self.filename}"

    def manifest_record(self) -> dict[str, object]:
        return {
            "id": self.identifier,
            "name": self.name,
            "category": self.category,
            "pageURL": self.url,
            "description": self.description,
            "appleDocumentationURL": self.apple_documentation_url,
            "programmingLanguage": self.programming_language,
            "runtimePlatform": self.runtime_platform,
            "publishedAt": self.published_at,
            "updatedAt": self.updated_at,
            "tags": list(self.tags),
            "platforms": self.platforms,
            "sourcePath": self.source_path,
            "sha256": self.sha256,
            "bytes": len(self.source_bytes),
        }


class _PageParser(html.parser.HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self._in_json_ld = False
        self._json_parts: list[str] = []
        self.json_documents: list[str] = []
        self.visible_parts: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attributes = {key.lower(): value for key, value in attrs}
        if tag.lower() == "script" and attributes.get("type") == "application/ld+json":
            self._in_json_ld = True
            self._json_parts = []

    def handle_endtag(self, tag: str) -> None:
        if tag.lower() == "script" and self._in_json_ld:
            self.json_documents.append("".join(self._json_parts))
            self._in_json_ld = False
            self._json_parts = []

    def handle_data(self, data: str) -> None:
        if self._in_json_ld:
            self._json_parts.append(data)
        elif data.strip():
            self.visible_parts.append(data)


def _node_has_type(node: dict[str, object], expected: str) -> bool:
    node_type = node.get("@type")
    if isinstance(node_type, str):
        return node_type == expected
    return isinstance(node_type, list) and expected in node_type


def _json_ld_nodes(documents: Iterable[str]) -> list[dict[str, object]]:
    nodes: list[dict[str, object]] = []
    for document in documents:
        payload = json.loads(document)
        candidates: list[object]
        if isinstance(payload, dict) and isinstance(payload.get("@graph"), list):
            candidates = payload["@graph"]
        elif isinstance(payload, list):
            candidates = payload
        else:
            candidates = [payload]
        nodes.extend(candidate for candidate in candidates if isinstance(candidate, dict))
    return nodes


def _required_string(node: dict[str, object], key: str, context: str) -> str:
    value = node.get(key)
    if not isinstance(value, str) or not value:
        raise ValueError(f"{context}: missing {key}")
    return value


def _optional_string(node: dict[str, object], key: str) -> str:
    value = node.get(key)
    return value if isinstance(value, str) else ""


def _pascal_filename(value: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9]+", " ", value).strip()
    if not cleaned:
        raise ValueError("component name cannot produce a Swift filename")
    stem = "".join(part[0].upper() + part[1:] for part in cleaned.split())
    if stem[0].isdigit():
        stem = f"Component{stem}"
    return f"{stem}.swift"


def discover_detail_urls(xml: bytes) -> list[str]:
    root = ET.fromstring(xml)
    urls: set[str] = set()
    for element in root.iter():
        if element.tag.rsplit("}", 1)[-1] != "loc" or not element.text:
            continue
        url = element.text.strip()
        parsed = urllib.parse.urlparse(url)
        parts = [part for part in parsed.path.split("/") if part]
        if parsed.netloc == "exploreswiftui.com" and len(parts) == 3 and parts[0] == "library":
            urls.add(url.rstrip("/"))
    return sorted(urls)


def parse_component_page(url: str, html: bytes) -> NativePattern:
    parser = _PageParser()
    parser.feed(html.decode("utf-8"))
    nodes = _json_ld_nodes(parser.json_documents)
    source_nodes = [node for node in nodes if _node_has_type(node, "SoftwareSourceCode")]
    if len(source_nodes) != 1:
        raise ValueError(f"{url}: expected exactly one SoftwareSourceCode node")
    source_node = source_nodes[0]

    page_node = next(
        (
            node
            for node in nodes
            if _node_has_type(node, "WebPage") or _node_has_type(node, "Article")
        ),
        {},
    )
    breadcrumb = next(
        (node for node in nodes if _node_has_type(node, "BreadcrumbList")),
        {},
    )
    breadcrumb_items = breadcrumb.get("itemListElement", [])
    category = ""
    if isinstance(breadcrumb_items, list):
        for item in breadcrumb_items:
            if isinstance(item, dict) and item.get("position") == 2:
                category = _optional_string(item, "name")
                break

    parts = [part for part in urllib.parse.urlparse(url).path.split("/") if part]
    if len(parts) != 3 or parts[0] != "library":
        raise ValueError(f"{url}: not an Explore SwiftUI detail URL")
    if not category:
        category = _pascal_filename(parts[1]).removesuffix(".swift")

    name = _required_string(source_node, "name", url)
    raw_tags = source_node.get("about", [])
    tags: list[str] = []
    if isinstance(raw_tags, list):
        for item in raw_tags:
            if isinstance(item, str) and item:
                tags.append(item)
            elif isinstance(item, dict):
                tag_name = item.get("name")
                if isinstance(tag_name, str) and tag_name:
                    tags.append(tag_name)

    visible_text = " ".join(parser.visible_parts)
    platform_pattern = re.compile(
        rf"\b({'|'.join(map(re.escape, PLATFORMS))})\s*(\d+(?:\.\d+){{0,2}}\s*\+)",
        re.IGNORECASE,
    )
    canonical_names = {platform.lower(): platform for platform in PLATFORMS}
    platforms: dict[str, str] = {}
    for match in platform_pattern.finditer(visible_text):
        platforms[canonical_names[match.group(1).lower()]] = match.group(2).replace(" ", "")

    return NativePattern(
        identifier="/".join(parts[1:]),
        name=name,
        category=_pascal_filename(category).removesuffix(".swift"),
        filename=_pascal_filename(name),
        url=url,
        description=_optional_string(source_node, "description"),
        apple_documentation_url=_optional_string(source_node, "codeRepository"),
        programming_language=_optional_string(source_node, "programmingLanguage"),
        runtime_platform=_optional_string(source_node, "runtimePlatform"),
        published_at=_optional_string(page_node, "datePublished"),
        updated_at=_optional_string(page_node, "dateModified"),
        tags=tuple(sorted(set(tags))),
        platforms=dict(sorted(platforms.items())),
        source=_required_string(source_node, "text", url),
    )


def build_catalog(patterns: Iterable[NativePattern], version: str) -> dict[str, object]:
    records: list[dict[str, object]] = []
    identifiers: set[str] = set()
    source_paths: set[str] = set()
    for pattern in sorted(patterns, key=lambda item: item.identifier):
        if pattern.identifier in identifiers:
            raise ValueError(f"duplicate component id: {pattern.identifier}")
        if pattern.source_path in source_paths:
            raise ValueError(f"duplicate source path: {pattern.source_path}")
        identifiers.add(pattern.identifier)
        source_paths.add(pattern.source_path)
        records.append(pattern.manifest_record())
    if not records:
        raise ValueError("Explore SwiftUI catalog is empty")
    return {
        "version": version,
        "source": SITE_URL,
        "sitemap": SITEMAP_URL,
        "count": len(records),
        "components": records,
    }


def _read_manifest(path: Path) -> dict[str, object]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path}: manifest must be an object")
    return payload


def verify_catalog(package_root: Path, manifest_path: Path) -> None:
    manifest = _read_manifest(manifest_path)
    records = manifest.get("components")
    if not isinstance(records, list) or not records:
        raise ValueError(f"{manifest_path}: components must be a non-empty array")
    if manifest.get("count", len(records)) != len(records):
        raise ValueError(f"{manifest_path}: count mismatch")

    expected_paths: set[str] = set()
    identifiers: set[str] = set()
    for record in records:
        if not isinstance(record, dict):
            raise ValueError(f"{manifest_path}: invalid component record")
        identifier = record.get("id")
        source_path = record.get("sourcePath")
        if not isinstance(identifier, str) or not identifier:
            raise ValueError(f"{manifest_path}: invalid component id")
        if identifier in identifiers:
            raise ValueError(f"{manifest_path}: duplicate component id: {identifier}")
        identifiers.add(identifier)
        if not isinstance(source_path, str) or not source_path.startswith(
            "Sources/ExploreSwiftUI/Components/"
        ):
            raise ValueError(f"{manifest_path}: invalid source path for {identifier}")
        if source_path in expected_paths:
            raise ValueError(f"{manifest_path}: duplicate source path: {source_path}")
        expected_paths.add(source_path)
        path = (package_root / source_path).resolve()
        component_root = (package_root / "Sources/ExploreSwiftUI/Components").resolve()
        if component_root not in path.parents:
            raise ValueError(f"{manifest_path}: source path escapes component root")
        if not path.is_file():
            raise ValueError(f"missing original source: {source_path}")
        payload = path.read_bytes()
        if record.get("bytes") != len(payload):
            raise ValueError(f"byte-size mismatch: {source_path}")
        if record.get("sha256") != hashlib.sha256(payload).hexdigest():
            raise ValueError(f"hash mismatch: {source_path}")

    component_root = package_root / "Sources/ExploreSwiftUI/Components"
    actual_paths = {
        path.relative_to(package_root).as_posix()
        for path in component_root.rglob("*.swift")
        if path.is_file()
    }
    missing = sorted(expected_paths - actual_paths)
    unexpected = sorted(actual_paths - expected_paths)
    if missing:
        raise ValueError(f"manifest sources are missing: {', '.join(missing)}")
    if unexpected:
        raise ValueError(f"untracked original sources: {', '.join(unexpected)}")


def derive_component(package_root: Path, identifier: str, output_name: str) -> Path:
    if not re.fullmatch(r"[A-Z][A-Za-z0-9_]*", output_name):
        raise ValueError("output name must be a Swift type-style identifier")
    manifest_path = package_root / "Sources/ExploreSwiftUI/manifest.json"
    verify_catalog(package_root, manifest_path)
    manifest = _read_manifest(manifest_path)
    record = next(
        (
            item
            for item in manifest["components"]
            if isinstance(item, dict) and item.get("id") == identifier
        ),
        None,
    )
    if record is None:
        raise ValueError(f"unknown Explore SwiftUI component id: {identifier}")
    source = package_root / str(record["sourcePath"])
    output = package_root / f"Sources/QenTerra/Components/{output_name}.swift"
    if output.exists():
        raise ValueError(f"QenTerra component already exists: {output.name}")
    repository_root = package_root.parent
    qenterra_registry_path = repository_root / "registry/qenterra-components.json"
    qenterra_registry: dict[str, object] | None = None
    package_registry_path = repository_root / "registry/packages.json"
    package_registry: dict[str, object] | None = None
    if qenterra_registry_path.is_file():
        qenterra_registry = _read_manifest(qenterra_registry_path)
        components = qenterra_registry.get("components")
        if not isinstance(components, list):
            raise ValueError("registry/qenterra-components.json: components must be an array")
        component_id = re.sub(r"(?<!^)(?=[A-Z])", "-", output_name).lower()
        relative_output = output.relative_to(repository_root).as_posix()
        if any(
            isinstance(component, dict)
            and (
                component.get("id") == component_id
                or component.get("sourcePath") == relative_output
            )
            for component in components
        ):
            raise ValueError(f"QenTerra component is already registered: {component_id}")
        components.append(
            {
                "id": component_id,
                "name": output_name,
                "category": "adapted",
                "status": "draft",
                "sourcePath": relative_output,
                "publicSymbols": [output_name],
                "designTokens": False,
                "derivedFrom": {
                    "provider": "Explore SwiftUI",
                    "componentId": identifier,
                    "pageURL": record.get("pageURL", ""),
                    "sourceSha256": record["sha256"],
                },
            }
        )
        components.sort(key=lambda component: str(component.get("id", "")))

        if package_registry_path.is_file():
            package_registry = _read_manifest(package_registry_path)
            package_entries = package_registry.get("packages")
            swift_package = next(
                (
                    package
                    for package in package_entries
                    if isinstance(package, dict) and package.get("id") == "swift-components"
                ),
                None,
            ) if isinstance(package_entries, list) else None
            if swift_package is None or not isinstance(swift_package.get("publicPaths"), list):
                raise ValueError("registry/packages.json: swift-components package is missing")
            if relative_output not in swift_package["publicPaths"]:
                swift_package["publicPaths"].append(relative_output)
                swift_package["publicPaths"].sort()
    output.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, output)
    if qenterra_registry is not None:
        qenterra_registry_path.write_text(
            json.dumps(qenterra_registry, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    if package_registry is not None:
        package_registry_path.write_text(
            json.dumps(package_registry, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    return output


def _fetch(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read()


def fetch_live_patterns() -> list[NativePattern]:
    urls = discover_detail_urls(_fetch(SITEMAP_URL))
    if not urls:
        raise ValueError("Explore SwiftUI sitemap contains no detail pages")
    with concurrent.futures.ThreadPoolExecutor(max_workers=12) as executor:
        pages = list(executor.map(_fetch, urls))
    if len(urls) != len(pages):
        raise ValueError("Explore SwiftUI fetch returned an incomplete page set")
    return [parse_component_page(url, page) for url, page in zip(urls, pages)]


def _catalog_json(catalog: dict[str, object], *, schema: str | None = None) -> str:
    payload = dict(catalog)
    if schema:
        payload = {"$schema": schema, **payload}
    return json.dumps(payload, ensure_ascii=False, indent=2) + "\n"


def _package_registry_with_explore_paths(
    root: Path,
    patterns: list[NativePattern],
) -> bytes:
    registry_path = root / "registry/packages.json"
    registry = _read_manifest(registry_path)
    packages = registry.get("packages")
    if not isinstance(packages, list):
        raise ValueError("registry/packages.json: packages must be an array")
    metadata = next(
        (
            package
            for package in packages
            if isinstance(package, dict) and package.get("id") == "repository-metadata"
        ),
        None,
    )
    if metadata is None or not isinstance(metadata.get("publicPaths"), list):
        raise ValueError("registry/packages.json: repository-metadata package is missing")
    retained = [
        path
        for path in metadata["publicPaths"]
        if isinstance(path, str)
        and not path.startswith("packages/Sources/ExploreSwiftUI/")
    ]
    explore_paths = [
        "packages/Sources/ExploreSwiftUI/README.md",
        "packages/Sources/ExploreSwiftUI/manifest.json",
        *[f"packages/{pattern.source_path}" for pattern in patterns],
    ]
    metadata["publicPaths"] = [*retained, *sorted(explore_paths)]
    return (json.dumps(registry, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def _expected_files(patterns: list[NativePattern], version: str) -> dict[Path, bytes]:
    catalog = build_catalog(patterns, version)
    files = {
        ROOT / PUBLIC_MANIFEST: _catalog_json(catalog).encode("utf-8"),
        ROOT / PRIVATE_REGISTRY: _catalog_json(
            catalog,
            schema="../schemas/native-pattern-registry.schema.json",
        ).encode("utf-8"),
        ROOT / "registry/packages.json": _package_registry_with_explore_paths(
            ROOT,
            patterns,
        ),
    }
    for pattern in patterns:
        files[ROOT / "packages" / pattern.source_path] = pattern.source_bytes
    return files


def sync_catalog(*, write: bool, root: Path = ROOT) -> list[str]:
    global ROOT
    original_root = ROOT
    ROOT = root.resolve()
    try:
        version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
        patterns = fetch_live_patterns()
        expected = _expected_files(patterns, version)
        component_root = ROOT / COMPONENT_ROOT
        actual_sources = {
            path for path in component_root.rglob("*.swift") if path.is_file()
        } if component_root.is_dir() else set()
        expected_sources = {
            path for path in expected if COMPONENT_ROOT.as_posix() in path.as_posix()
        }
        changes = [
            path.relative_to(ROOT).as_posix()
            for path, payload in expected.items()
            if not path.is_file() or path.read_bytes() != payload
        ]
        changes.extend(
            path.relative_to(ROOT).as_posix()
            for path in sorted(actual_sources - expected_sources)
        )
        changes = sorted(set(changes))
        if write:
            for path in actual_sources - expected_sources:
                path.unlink()
            for path, payload in expected.items():
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(payload)
        return changes
    finally:
        ROOT = original_root


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    sync = subparsers.add_parser("sync", help="compare with or write the live catalog")
    mode = sync.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--write", action="store_true")
    subparsers.add_parser("verify", help="verify the stored catalog without network access")
    derive = subparsers.add_parser("derive", help="copy an original into QenTerra components")
    derive.add_argument("--id", required=True, dest="identifier")
    derive.add_argument("--output", required=True, dest="output_name")
    arguments = parser.parse_args(argv)

    try:
        if arguments.command == "sync":
            changes = sync_catalog(write=arguments.write)
            if changes and arguments.check:
                print("Explore SwiftUI catalog is stale:", file=sys.stderr)
                for change in changes:
                    print(f"- {change}", file=sys.stderr)
                return 1
            action = "Updated" if arguments.write else "Verified"
            manifest = _read_manifest(ROOT / PUBLIC_MANIFEST)
            print(f"{action} {manifest['count']} Explore SwiftUI components")
            return 0
        if arguments.command == "verify":
            verify_catalog(ROOT / "packages", ROOT / PUBLIC_MANIFEST)
            manifest = _read_manifest(ROOT / PUBLIC_MANIFEST)
            print(f"Verified {manifest['count']} immutable Explore SwiftUI components")
            return 0
        output = derive_component(
            ROOT / "packages",
            arguments.identifier,
            arguments.output_name,
        )
        generator = ROOT / "scripts/generate.py"
        if generator.is_file():
            subprocess.run(
                [sys.executable, str(generator), "write"],
                cwd=ROOT,
                check=True,
            )
        print(output.relative_to(ROOT))
        return 0
    except (
        ET.ParseError,
        OSError,
        ValueError,
        json.JSONDecodeError,
        subprocess.CalledProcessError,
    ) as error:
        print(f"Explore SwiftUI operation failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
