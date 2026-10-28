#!/usr/bin/env python3
"""抽取 Haskell.md 中的围栏代码块。

用法：
    python3 tools/extract_snippets.py            # 读取 ../Haskell.md（相对本脚本）
    python3 tools/extract_snippets.py --src X.md

产出（都放在项目根的 snippets/ 下）：
    NN-<lang>.hs     按出现顺序编号的代码块，文件头注释记录原文行号区间
    _report.csv      序号,起始行,结束行,语言标记,行数,是否含省略号或全角括号或其他非ASCII代码字符

只用标准库。不改动 ../Haskell.md。
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SRC = ROOT / "Haskell.md"      # 即 tools/../Haskell.md
OUT_DIR = ROOT / "snippets"

# ```lang 开始，``` 结束（允许围栏后带空白）
FENCE_OPEN = re.compile(r"^```([^\s`]*)\s*$")
FENCE_CLOSE = re.compile(r"^```\s*$")

FULLWIDTH_PARENS = "（）"
ELLIPSES = ("…", "...")
CSV_HEADER = [
    "序号",
    "起始行",
    "结束行",
    "语言标记",
    "行数",
    "是否含省略号或全角括号或其他非ASCII代码字符",
]


def strip_comments(src: str) -> str:
    """去掉 Haskell 的行注释与块注释，保留字符串字面量。

    只用于判定「代码字符」是否含非 ASCII，因此对字符串里的 `--` 也做了保护。
    """
    out: list[str] = []
    i, n = 0, len(src)
    in_str = False
    block = 0
    while i < n:
        c = src[i]
        if block:
            if src.startswith("{-", i):
                block += 1
                i += 2
                continue
            if src.startswith("-}", i):
                block -= 1
                i += 2
                continue
            i += 1
            continue
        if in_str:
            out.append(c)
            if c == "\\":
                out.append(src[i + 1 : i + 2])
                i += 2
                continue
            if c == '"':
                in_str = False
            i += 1
            continue
        if src.startswith("{-", i):
            block = 1
            i += 2
            continue
        if src.startswith("--", i):
            j = src.find("\n", i)
            if j < 0:
                break
            i = j
            continue
        if c == '"':
            in_str = True
            out.append(c)
            i += 1
            continue
        out.append(c)
        i += 1
    return "".join(out)


def scan(body: str) -> str:
    """返回该块「是否含特殊字符」的中文说明。"""
    code = strip_comments(body)
    reasons: list[str] = []
    if any(e in code for e in ELLIPSES):
        reasons.append("省略号")
    if any(p in code for p in FULLWIDTH_PARENS):
        reasons.append("全角括号")
    others = sorted({ch for ch in code if ord(ch) > 127})
    if others:
        reasons.append("其他非ASCII代码字符:" + "".join(others[:8]))
    return "是(" + ";".join(reasons) + ")" if reasons else "否"


def extract(lines: list[str]) -> list[dict]:
    blocks: list[dict] = []
    i = 0
    while i < len(lines):
        m = FENCE_OPEN.match(lines[i])
        if not m:
            i += 1
            continue
        lang = m.group(1) or "txt"
        start = i + 1            # 1-based 行号：``` 所在行
        j = i + 1
        while j < len(lines) and not FENCE_CLOSE.match(lines[j]):
            j += 1
        if j >= len(lines):
            raise SystemExit(f"第 {start} 行的围栏没有闭合，已中止")
        body_lines = lines[i + 1 : j]
        blocks.append(
            {
                "idx": len(blocks) + 1,
                "lang": lang,
                "start": start,
                "end": j + 1,             # 闭合 ``` 的 1-based 行号
                "body": "\n".join(body_lines),
                "nlines": len(body_lines),
            }
        )
        i = j + 1
    return blocks


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=str(DEFAULT_SRC))
    ap.add_argument("--out", default=str(OUT_DIR))
    args = ap.parse_args()

    src = Path(args.src).resolve()
    out_dir = Path(args.out).resolve()
    if not src.is_file():
        print(f"找不到源文件：{src}", file=sys.stderr)
        return 2

    text = src.read_text(encoding="utf-8")
    lines = text.splitlines()
    blocks = extract(lines)

    out_dir.mkdir(parents=True, exist_ok=True)
    for old in sorted(out_dir.glob("[0-9][0-9]-*")):
        old.unlink()

    rows = []
    for b in blocks:
        name = f"{b['idx']:02d}-{b['lang']}.hs"
        header = (
            f"-- snippet {b['idx']:02d} | {src.name}:L{b['start']}-L{b['end']}"
            f" | lang={b['lang']} | code-lines={b['nlines']}\n"
            f"-- 原文第 {b['start']} 行是开始围栏，代码对应原文第 {b['start'] + 1}"
            f"-{b['end'] - 1} 行\n"
        )
        (out_dir / name).write_text(header + b["body"] + "\n", encoding="utf-8")
        rows.append(
            [
                b["idx"],
                b["start"],
                b["end"],
                b["lang"],
                b["nlines"],
                scan(b["body"]),
            ]
        )

    csv_path = out_dir / "_report.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(CSV_HEADER)
        w.writerows(rows)

    print(f"源文件：{src}")
    print(f"输出目录：{out_dir}")
    print(f"代码块总数：{len(rows)}")
    print(f"{'序号':<4}{'起始':>5}{'结束':>6}{'语言':>10}{'行数':>6}  特殊字符")
    for r in rows:
        print(f"{r[0]:<4}{r[1]:>5}{r[2]:>6}{r[3]:>10}{r[4]:>6}  {r[5]}")
    print(f"CSV：{csv_path}（{len(rows) + 1} 行，含表头）")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
