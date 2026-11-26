#!/usr/bin/env python3
"""Normalize chapter titles to the form '第 N 章 <title>' in SUMMARY.md and page H1s.

Idempotent. Keeps the sidebar and each page's first heading in sync; the chapter
number is read from the filename (chNN-*.md).
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"

summary = SRC / "SUMMARY.md"
lines = summary.read_text(encoding="utf-8").splitlines()
titles = {}
out = []
for line in lines:
    m = re.match(r"- \[(.*?)\]\((ch\d\d-[^)]+\.md)\)$", line)
    if m:
        title, slug = m.group(1), m.group(2)
        num = int(slug[2:4])
        title = re.sub(r"^第\s*\d+\s*章\s*", "", title)
        titles[slug] = (num, title)
        line = f"- [第 {num} 章 {title}]({slug})"
    out.append(line)
summary.write_text("\n".join(out) + "\n", encoding="utf-8")

for slug, (num, title) in titles.items():
    path = SRC / slug
    text = path.read_text(encoding="utf-8").splitlines()
    if text and text[0].startswith("# "):
        text[0] = f"# 第 {num} 章 {title}"
        path.write_text("\n".join(text) + "\n", encoding="utf-8")

print(f"normalized {len(titles)} chapters")
