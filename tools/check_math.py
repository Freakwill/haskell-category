#!/usr/bin/env python3
"""Check inline math ($...$) in src/*.md.

Rule: every inline span must open and close on the same physical line, because
MathJax in mdBook will not render a span that contains a newline. Fenced code,
inline code and display math ($$...$$) are masked first; then every remaining
line must contain an even number of dollar signs.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"


def blank(s: str) -> str:
    return re.sub(r"[^\n]", " ", s)


def masked_lines(path: Path):
    raw = path.read_text(encoding="utf-8")
    masked = re.sub(r"```.*?```", lambda m: blank(m.group(0)), raw, flags=re.S)
    masked = re.sub(r"`[^`\n]*`", lambda m: blank(m.group(0)), masked)
    masked = re.sub(r"\$\$.*?\$\$", lambda m: blank(m.group(0)), masked, flags=re.S)
    return raw.splitlines(), masked.splitlines()


def main() -> int:
    total = 0
    for path in sorted(SRC.glob("*.md")):
        raw_lines, masked = masked_lines(path)
        for i, line in enumerate(masked, start=1):
            if line.count("$") % 2:
                total += 1
                print(f"{path.name}:{i}: 行内公式未配对 -> {raw_lines[i - 1].strip()[:90]}")
    print(f"total: {total}")
    return 0 if total == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
