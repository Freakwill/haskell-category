#!/usr/bin/env python3
"""Validate claim tables under claims/ and report per-chapter status counts."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CLAIMS = ROOT / "claims"
STATUSES = {"✓", "✗", "待核"}
COLUMNS = ["ID", "断言", "位置", "依据", "核验", "状态"]


def split_row(line: str) -> list[str]:
    line = line.strip()
    if line.startswith("|"):
        line = line[1:]
    if line.endswith("|"):
        line = line[:-1]
    cells, buf, escaped = [], [], False
    for ch in line:
        if escaped:
            buf.append(ch)
            escaped = False
        elif ch == "\\":
            buf.append(ch)
            escaped = True
        elif ch == "|":
            cells.append("".join(buf).strip())
            buf = []
        else:
            buf.append(ch)
    cells.append("".join(buf).strip())
    return cells


def main() -> int:
    if not CLAIMS.is_dir():
        print("no claims/ directory")
        return 1

    total = {"✓": 0, "✗": 0, "待核": 0}
    errors: list[str] = []
    rows_seen = 0

    for path in sorted(CLAIMS.glob("ch*.md")):
        text = path.read_text(encoding="utf-8").splitlines()
        chapter = re.sub(r"\D", "", path.stem)
        counts = {"✓": 0, "✗": 0, "待核": 0}
        header_checked = False

        for lineno, line in enumerate(text, start=1):
            if not line.lstrip().startswith("|"):
                continue
            cells = split_row(line)
            if cells and cells[0] == "ID":
                if cells != COLUMNS:
                    errors.append(f"{path.name}:{lineno} 表头应为 {' '.join(COLUMNS)}")
                header_checked = True
                continue
            if set("".join(cells)) <= set("-: "):
                continue

            rows_seen += 1
            if len(cells) != len(COLUMNS):
                errors.append(f"{path.name}:{lineno} 列数为 {len(cells)}，应为 6")
                continue
            ident, _, _, basis, _, status = cells
            if ident.split(".")[0] != str(int(chapter)):
                errors.append(f"{path.name}:{lineno} ID {ident} 与章号 {chapter} 不符")
            if basis not in {"S", "C", "T", "S+C", "C+S", "C+T", "T+C"}:
                errors.append(f"{path.name}:{lineno} 依据 {basis} 不在 S/C/T 之内")
            if status not in STATUSES:
                errors.append(f"{path.name}:{lineno} 状态 {status} 不在 ✓/✗/待核 之内")
                continue
            counts[status] += 1
            total[status] += 1

        if not header_checked:
            errors.append(f"{path.name} 缺少表头")
        print(
            f"{path.stem}: {counts['✓']:2d} ✓  {counts['✗']:2d} ✗  "
            f"{counts['待核']:2d} 待核"
        )

    print(f"total: {rows_seen} rows | {total['✓']} ✓ {total['✗']} ✗ {total['待核']} 待核")
    for err in errors:
        print("ERR", err)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
