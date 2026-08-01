"""Small deterministic Markdown renderer for the system reference.

The canonical document intentionally uses a constrained Markdown subset so the
static site can be rebuilt with the Python standard library only.
"""

from __future__ import annotations

import html
import re
from dataclasses import dataclass


@dataclass(frozen=True)
class Section:
    number: int
    title: str
    markdown: str

    @property
    def slug(self) -> str:
        value = re.sub(r"[^a-z0-9]+", "-", self.title.lower()).strip("-")
        return value or f"section-{self.number}"


def split_numbered_sections(markdown: str) -> tuple[str, list[Section]]:
    lines = markdown.splitlines()
    title = lines[0].removeprefix("# ").strip() if lines else "Design System"
    sections: list[Section] = []
    current_number: int | None = None
    current_title = ""
    current_lines: list[str] = []

    for line in lines[1:]:
        match = re.match(r"^## (\d+)\.\s+(.+)$", line)
        if match:
            if current_number is not None:
                sections.append(
                    Section(current_number, current_title, "\n".join(current_lines).strip())
                )
            current_number = int(match.group(1))
            current_title = match.group(2).strip()
            current_lines = []
            continue
        if current_number is not None:
            current_lines.append(line)

    if current_number is not None:
        sections.append(Section(current_number, current_title, "\n".join(current_lines).strip()))
    return title, sections


def inline(value: str) -> str:
    escaped = html.escape(value, quote=False)
    code_stash: list[str] = []

    def stash_code(match: re.Match[str]) -> str:
        code_stash.append(f"<code>{html.escape(match.group(1))}</code>")
        return f"\x00CODE{len(code_stash) - 1}\x00"

    escaped = re.sub(r"`([^`]+)`", stash_code, escaped)
    escaped = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", escaped)
    escaped = re.sub(r"\[([^]]+)]\(([^)]+)\)", r'<a href="\2">\1</a>', escaped)
    for index, code in enumerate(code_stash):
        escaped = escaped.replace(f"\x00CODE{index}\x00", code)
    return escaped


def render(markdown: str, heading_offset: int = 0, id_prefix: str = "") -> str:
    lines = markdown.splitlines()
    output: list[str] = []
    paragraph: list[str] = []
    list_kind: str | None = None
    code_lines: list[str] = []
    in_code = False
    code_language = ""
    slug_counts: dict[str, int] = {}
    index = 0

    def flush_paragraph() -> None:
        if paragraph:
            output.append(f"<p>{inline(' '.join(part.strip() for part in paragraph))}</p>")
            paragraph.clear()

    def close_list() -> None:
        nonlocal list_kind
        if list_kind:
            output.append(f"</{list_kind}>")
            list_kind = None

    while index < len(lines):
        line = lines[index]

        if line.startswith("```"):
            flush_paragraph()
            close_list()
            if not in_code:
                in_code = True
                code_language = line[3:].strip()
                code_lines = []
            else:
                language_class = f' class="language-{html.escape(code_language)}"' if code_language else ""
                code = html.escape("\n".join(code_lines))
                output.append(f"<pre><code{language_class}>{code}</code></pre>")
                in_code = False
            index += 1
            continue

        if in_code:
            code_lines.append(line)
            index += 1
            continue

        if not line.strip():
            flush_paragraph()
            close_list()
            index += 1
            continue

        if line.startswith("|") and index + 1 < len(lines):
            separator = lines[index + 1]
            if re.match(r"^\|?\s*:?-+", separator):
                flush_paragraph()
                close_list()
                headers = [cell.strip() for cell in line.strip("|").split("|")]
                output.append("<div class=\"table-scroll\"><table><thead><tr>")
                output.extend(f"<th>{inline(cell)}</th>" for cell in headers)
                output.append("</tr></thead><tbody>")
                index += 2
                while index < len(lines) and lines[index].startswith("|"):
                    cells = [cell.strip() for cell in lines[index].strip("|").split("|")]
                    output.append("<tr>")
                    output.extend(f"<td>{inline(cell)}</td>" for cell in cells)
                    output.append("</tr>")
                    index += 1
                output.append("</tbody></table></div>")
                continue

        heading = re.match(r"^(#{1,4})\s+(.+)$", line)
        if heading:
            flush_paragraph()
            close_list()
            level = min(6, len(heading.group(1)) + heading_offset)
            text = heading.group(2).strip()
            slug = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
            count = slug_counts.get(slug, 0) + 1
            slug_counts[slug] = count
            suffix = "" if count == 1 else f"-{count}"
            output.append(f'<h{level} id="{id_prefix}{slug}{suffix}">{inline(text)}</h{level}>')
            index += 1
            continue

        unordered = re.match(r"^\s*-\s+(.+)$", line)
        ordered = re.match(r"^\s*\d+\.\s+(.+)$", line)
        if unordered or ordered:
            flush_paragraph()
            kind = "ul" if unordered else "ol"
            if list_kind != kind:
                close_list()
                output.append(f"<{kind}>")
                list_kind = kind
            match = unordered or ordered
            assert match is not None
            output.append(f"<li>{inline(match.group(1))}</li>")
            index += 1
            continue

        if line.startswith("> "):
            flush_paragraph()
            close_list()
            output.append(f"<blockquote>{inline(line[2:].strip())}</blockquote>")
            index += 1
            continue

        paragraph.append(line)
        index += 1

    flush_paragraph()
    close_list()
    if in_code:
        raise ValueError("Unclosed fenced code block in docs/MASTER.md")
    return "\n".join(output)


def plain_text(markdown: str) -> str:
    value = re.sub(r"```.*?```", " ", markdown, flags=re.DOTALL)
    value = re.sub(r"[`*_>#|\[\]()]", " ", value)
    value = re.sub(r"\s+", " ", value)
    return value.strip()
