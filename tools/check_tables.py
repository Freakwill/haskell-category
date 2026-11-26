#!/usr/bin/env python3
"""Check that every Markdown table has a valid header separator row.

A table is a run of consecutive lines starting with `|`. The second line must
be a separator such as `|---|---|` (dashes, optional colons), and the column
count must match the header. Missing separators make mdBook render the block
as plain text. Fenced code and `$$` display math are skipped, and escaped
pipes (\\|) inside cells are not counted.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"

SEP = re.compile(r"^\|(\s*:?-{3,}:?\s*\|)+\s*$")


def cells(line: str) -> int:
    return line.strip().strip("|").replace("\\|", "").count("|") + 1


def check(path: Path):
    lines = path.read_text(encoding="utf-8").splitlines()
    problems = []
    in_fence = False
    in_math = False
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        if stripped.startswith("```"):
            in_fence = not in_fence
            i += 1
            continue
        if not in_fence and stripped.startswith("$$"):
            # a display block either opens and closes on this line, or toggles
            if stripped.count("$$") == 1:
                in_math = not in_math
            i += 1
            continue
        if in_fence or in_math:
            i += 1
            continue
        if line.lstrip().startswith("|"):
            start = i
            block = []
            while i < len(lines) and lines[i].lstrip().startswith("|"):
                block.append(lines[i])
                i += 1
            if len(block) < 2:
                problems.append((start + 1, "表格只有一行，缺少表头分隔行"))
            elif not SEP.match(block[1].strip()):
                problems.append((start + 2, "第二行不是合法的分隔行（|---|）"))
            elif cells(block[0]) != cells(block[1]):
                problems.append(
                    (start + 1, f"表头 {cells(block[0])} 列，分隔行 {cells(block[1])} 列")
                )
            else:
                width = cells(block[0])
                for j, row in enumerate(block[2:], start=start + 3):
                    if cells(row) != width:
                        problems.append((j, f"{cells(row)} 列，表头 {width} 列"))
            continue
        i += 1
    return problems


def main() -> int:
    total = 0
    for path in sorted(SRC.glob("*.md")):
        for line, msg in check(path):
            total += 1
            print(f"{path.name}:{line}: {msg}")
    print(f"total: {total}")
    return 0 if total == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
