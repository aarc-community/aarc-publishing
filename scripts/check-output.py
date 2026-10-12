#!/usr/bin/env python3
"""Check that every guideline was rendered, and rendered whole.

Quarto can finish a render and still write a PDF that is wrong: a
cross-reference it could not resolve is printed as ?@sec-name, and a font that
typst could not find is substituted without an error. This script reads each
PDF back and reports:

- a guideline that has no PDF, or a PDF older than its source,
- a guideline whose front matter lacks a field the cover requires,
- a grid table, or a ::: fence without a blank line on each side, which
  prettier destroys without a warning: it flattens the table into a paragraph,
  and joins the fence to the text beside it,
- an ORCID iD that is not in the form 0000-0000-0000-0000 or whose check digit
  is wrong, which would link the cover to someone else's record or to none,
- a font that is not embedded,
- an unresolved cross-reference or citation left in the text.

`just ci` runs it after the render, in this repository and in a repository of
guidelines, where the toolchain provides it as the command aarc-check. It needs
pdffonts and pdftotext from poppler, which the toolchain supplies. Give the
sources as a glob, relative to the project root:

    aarc-check 'guidelines/*/*.qmd'
"""

import glob
import os
import re
import subprocess
import sys

DEFAULT_SOURCES = "guidelines/*/*.qmd"
OUTPUT = "generated"

# The cover is incomplete without these.
REQUIRED = ("title", "document-code", "publication-date", "author", "abstract")

UNRESOLVED = re.compile(r"\?@[\w-]+|\[\?[\w-]+\]|\?\?")

ORCID_FIELD = re.compile(r"^[\s-]*orcid:\s*[\"']?([^\"'\s]+)", re.M)
ORCID_FORM = re.compile(r"\d{4}-\d{4}-\d{4}-\d{3}[\dX]")


def front_matter(path: str) -> str:
    with open(path, encoding="utf8") as source:
        parts = source.read().split("---", 2)
    return parts[1] if len(parts) == 3 else ""


GRID_BORDER = re.compile(r"^\+[-=:]+(\+[-=:]+)*\+?\s*$")
FENCE = re.compile(r"^:{3,}")
JOINED_FENCE = re.compile(r"\S\s+:{3,}\s*$|^:{3,}\s*\{[^}]*\}\s+\S")


def source_problems(text: str) -> list[str]:
    """The markdown that prettier breaks. Code blocks are skipped, since their
    contents are not markdown."""
    problems = []
    lines = text.split("\n")
    in_code = False
    for number, line in enumerate(lines, start=1):
        if re.match(r"^\s*(```|~~~)", line):
            in_code = not in_code
            continue
        if in_code:
            continue
        if GRID_BORDER.match(line):
            # A table is reported once, at its first border.
            if number > 1 and lines[number - 2].startswith(("+", "|")):
                continue
            problems.append(
                f"line {number}: a grid table, which prettier flattens into a "
                "paragraph; write it as a list table"
            )
        elif JOINED_FENCE.search(line):
            problems.append(f"line {number}: a ::: fence joined to the text beside it")
        elif FENCE.match(line):
            before = lines[number - 2] if number > 1 else ""
            after = lines[number] if number < len(lines) else ""
            if before.strip() or after.strip():
                problems.append(
                    f"line {number}: a ::: fence needs a blank line before and "
                    "after it, or prettier joins it to the text"
                )
    return problems


def orcid_check_digit(digits: str) -> str:
    """The check digit of the first 15 digits of an ORCID iD, by ISO 7064
    MOD 11-2, as ORCID specifies it."""
    total = 0
    for digit in digits:
        total = (total + int(digit)) * 2
    result = (12 - total % 11) % 11
    return "X" if result == 10 else str(result)


def orcid_problems(front: str) -> list[str]:
    problems = []
    for orcid in ORCID_FIELD.findall(front):
        if not ORCID_FORM.fullmatch(orcid):
            problems.append(
                f"ORCID iD {orcid!r} is not in the form 0000-0000-0000-0000; "
                "give the iD alone, without https://orcid.org/"
            )
            continue
        digits = orcid.replace("-", "")
        if orcid_check_digit(digits[:15]) != digits[15]:
            problems.append(f"ORCID iD {orcid} has a wrong check digit")
    return problems


def run(*command: str) -> str:
    return subprocess.run(command, check=True, capture_output=True, text=True).stdout


def unembedded_fonts(pdf: str) -> list[str]:
    """The fonts whose emb column in the pdffonts table is no."""
    lines = run("pdffonts", pdf).splitlines()[2:]
    missing = []
    for line in lines:
        columns = line.split()
        # name type... encoding emb sub uni object generation
        if len(columns) >= 6 and columns[-5] == "no":
            missing.append(columns[0])
    return missing


def check(source: str) -> list[str]:
    problems = []
    pdf = os.path.join(OUTPUT, os.path.splitext(source)[0] + ".pdf")

    front = front_matter(source)
    with open(source, encoding="utf8") as document:
        problems += source_problems(document.read())
    for field in REQUIRED:
        if not re.search(rf"^{field}:", front, re.M):
            problems.append(f"the front matter has no {field}")
    problems += orcid_problems(front)

    if not os.path.exists(pdf):
        return problems + [f"no PDF at {pdf}"]
    if os.path.getmtime(pdf) < os.path.getmtime(source):
        problems.append(f"{pdf} is older than its source")

    for font in unembedded_fonts(pdf):
        problems.append(f"font {font} is not embedded")

    text = run("pdftotext", "-layout", pdf, "-")
    for found in sorted(set(UNRESOLVED.findall(text))):
        problems.append(f"unresolved reference {found!r} in the text")
    return problems


def main() -> int:
    pattern = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SOURCES
    sources = sorted(glob.glob(pattern))
    if not sources:
        print(f"check-output: no guideline matches {pattern}", file=sys.stderr)
        return 1
    failed = False
    for source in sources:
        problems = check(source)
        for problem in problems:
            print(f"check-output: {source}: {problem}", file=sys.stderr)
        failed = failed or bool(problems)
    if failed:
        return 1
    print(f"check-output: {len(sources)} guideline(s) clean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
