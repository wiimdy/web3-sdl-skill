#!/usr/bin/env python3

from __future__ import annotations

import sys
import textwrap
from pathlib import Path

PAGE_WIDTH = 612
PAGE_HEIGHT = 792
LEFT_MARGIN = 54
TOP_MARGIN = 738
FONT_SIZE = 10
LEADING = 14
MAX_LINES_PER_PAGE = 48


def usage() -> None:
    print(
        "Usage: render_plaintext_pdf.py <input-markdown> <output-pdf>",
        file=sys.stderr,
    )
    raise SystemExit(1)


def escape_pdf_text(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace("(", "\\(")
        .replace(")", "\\)")
    )


def wrap_markdown(markdown: str) -> list[str]:
    lines = markdown.splitlines()
    output: list[str] = []
    paragraph: list[str] = []
    in_code_block = False

    def flush_paragraph() -> None:
        nonlocal paragraph
        if not paragraph:
            return
        text = " ".join(part.strip() for part in paragraph if part.strip())
        if text:
            output.extend(textwrap.wrap(text, width=95))
        output.append("")
        paragraph = []

    for raw_line in lines:
        line = raw_line.expandtabs(2).rstrip()

        if line.startswith("```"):
            flush_paragraph()
            in_code_block = not in_code_block
            output.append(line)
            continue

        if in_code_block:
            output.append(line)
            continue

        if not line:
            flush_paragraph()
            continue

        if line.startswith("#"):
            flush_paragraph()
            output.append(line)
            output.append("")
            continue

        if line.startswith("- ") or line.startswith("* "):
            flush_paragraph()
            wrapped = textwrap.wrap(
                line[2:],
                width=91,
                initial_indent="- ",
                subsequent_indent="  ",
            )
            output.extend(wrapped or ["-"])
            continue

        numbered = None
        if len(line) > 3 and line[0].isdigit() and line[1] == "." and line[2] == " ":
            numbered = line[:3]

        if numbered:
            flush_paragraph()
            wrapped = textwrap.wrap(
                line[3:],
                width=90,
                initial_indent=numbered,
                subsequent_indent="   ",
            )
            output.extend(wrapped or [numbered.strip()])
            continue

        paragraph.append(line)

    flush_paragraph()

    while output and output[-1] == "":
        output.pop()

    return output or [""]


def paginate(lines: list[str]) -> list[list[str]]:
    pages: list[list[str]] = []
    current: list[str] = []

    for line in lines:
        if len(current) >= MAX_LINES_PER_PAGE:
            pages.append(current)
            current = []
        current.append(line)

    if current or not pages:
        pages.append(current)

    return pages


def content_stream(lines: list[str]) -> bytes:
    commands = [
        "BT",
        f"/F1 {FONT_SIZE} Tf",
        f"{LEADING} TL",
        f"{LEFT_MARGIN} {TOP_MARGIN} Td",
    ]

    first = True
    for line in lines:
        safe = escape_pdf_text(line)
        if first:
            commands.append(f"({safe}) Tj")
            first = False
        else:
            commands.append("T*")
            commands.append(f"({safe}) Tj")

    commands.append("ET")
    return "\n".join(commands).encode("latin-1", "replace")


def build_pdf(pages: list[list[str]]) -> bytes:
    objects: dict[int, bytes] = {}
    objects[1] = b"<< /Type /Catalog /Pages 2 0 R >>"

    page_numbers: list[int] = []
    content_numbers: list[int] = []
    object_number = 4

    for _ in pages:
        content_numbers.append(object_number)
        page_numbers.append(object_number + 1)
        object_number += 2

    kids = " ".join(f"{num} 0 R" for num in page_numbers)
    objects[2] = f"<< /Type /Pages /Count {len(page_numbers)} /Kids [{kids}] >>".encode(
        "ascii"
    )
    objects[3] = b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"

    for index, lines in enumerate(pages):
        stream = content_stream(lines)
        content_number = content_numbers[index]
        page_number = page_numbers[index]
        objects[content_number] = (
            f"<< /Length {len(stream)} >>\nstream\n".encode("ascii")
            + stream
            + b"\nendstream"
        )
        objects[page_number] = (
            f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 {PAGE_WIDTH} {PAGE_HEIGHT}] "
            f"/Resources << /Font << /F1 3 0 R >> >> /Contents {content_number} 0 R >>"
        ).encode("ascii")

    object_count = max(objects)
    chunks = [b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n"]
    offsets = [0] * (object_count + 1)

    current_offset = len(chunks[0])
    for number in range(1, object_count + 1):
        body = (
            f"{number} 0 obj\n".encode("ascii")
            + objects[number]
            + b"\nendobj\n"
        )
        offsets[number] = current_offset
        chunks.append(body)
        current_offset += len(body)

    xref_offset = current_offset
    xref = [f"xref\n0 {object_count + 1}\n".encode("ascii")]
    xref.append(b"0000000000 65535 f \n")
    for number in range(1, object_count + 1):
        xref.append(f"{offsets[number]:010d} 00000 n \n".encode("ascii"))
    xref.append(
        (
            f"trailer\n<< /Size {object_count + 1} /Root 1 0 R >>\n"
            f"startxref\n{xref_offset}\n%%EOF\n"
        ).encode("ascii")
    )

    chunks.extend(xref)
    return b"".join(chunks)


def main() -> None:
    if len(sys.argv) != 3:
        usage()

    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])

    if not input_path.is_file():
        print(f"Input markdown file not found: {input_path}", file=sys.stderr)
        raise SystemExit(1)

    wrapped = wrap_markdown(input_path.read_text(encoding="utf-8"))
    pages = paginate(wrapped)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(build_pdf(pages))


if __name__ == "__main__":
    main()
