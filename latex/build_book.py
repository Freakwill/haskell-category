#!/usr/bin/env python3
"""Build the LaTeX book project (正文) and the sample (样稿) from the mdBook sources.

Layout:
  latex/book.tex            main file of the book itself (正文)
  latex/book-preamble.tex   shared preamble (used by both book.tex and sample.tex)
  latex/front.tex           内容简介 + 序
  latex/book-main.tex       parts I-V + \input chapters/chNN for all 14 chapters
  latex/chapters/chNN.tex   ch01/ch05: full text from md; others: title only (body empty)
  sample/sample.tex         样稿: same preamble/front/main via \input{../latex/...},
                            plus 样稿 title page and 样稿说明 (the only difference)

Conversion rules:
  - mdBook {{#include PATH:anchor}} blocks are expanded inside code fences.
  - Heading numbers ("5.1", "第 5 章") are stripped; LaTeX numbers headings itself.
  - ASCII commutative diagrams become TikZ.
  - Straight "..." becomes curly “...” outside code (pandoc smart quotes disabled).
  - Code is highlighted via listings.

Usage: python3 build_book.py   (compiles book.pdf and sample/样稿.pdf)
"""

import json
import re
import subprocess
import shutil
from pathlib import Path

ROOT = Path("/Users/will/Folders/mybooks/haskell-category")
SRC = ROOT / "src"
LATEX = ROOT / "latex"
FRAG = LATEX / "chapters"
SAMPLE = ROOT / "sample"
FRAG.mkdir(parents=True, exist_ok=True)
SAMPLE.mkdir(parents=True, exist_ok=True)

FULL_CHAPTERS = {1, 5}

INCLUDE_RE = re.compile(r"\{\{#include\s+(\S+?):([A-Za-z0-9_-]+)\}\}")


def extract_anchor(path: Path, anchor: str, lang: str) -> str:
    text = path.read_text(encoding="utf-8")
    start_marker = "-- ANCHOR: " if lang == "haskell" else "# ANCHOR: "
    end_marker = "-- ANCHOR_END: " if lang == "haskell" else "# ANCHOR_END: "
    lines = text.splitlines()
    start = end = None
    for i, ln in enumerate(lines):
        s = ln.strip()
        if start is None and s == (start_marker + anchor):
            start = i
        elif start is not None and s == (end_marker + anchor):
            end = i
            break
    if start is None or end is None:
        raise SystemExit(f"anchor '{anchor}' not found in {path}")
    return "\n".join(lines[start + 1 : end])


def expand_includes(md_text: str, md_dir: Path) -> str:
    def repl(m):
        rel, anchor = m.group(1), m.group(2)
        target = (md_dir / rel).resolve()
        lang = "python" if target.suffix == ".py" else "haskell"
        return extract_anchor(target, anchor, lang)

    return INCLUDE_RE.sub(repl, md_text)


def strip_status(md_text: str) -> str:
    return re.sub(r"^>\s*状态：.*\n", "", md_text, flags=re.M)


def strip_heading_numbers(md_text: str) -> str:
    """LaTeX numbers headings itself; drop the numbers written in the md.

    "# 第 5 章 范畴：..." -> "# 范畴：..." (LaTeX prints 第五章)
    "## 5.1 从复合律出发" -> "## 从复合律出发" (LaTeX prints 5.1)
    """
    md_text = re.sub(r"^(#{1})\s+第\s*\d+\s*章\s*", r"# ", md_text, flags=re.M)
    md_text = re.sub(
        r"^(#{2,3})\s+\d+\.\d+(\.\d+)?\s+",
        lambda m: m.group(1) + " ",
        md_text,
        flags=re.M,
    )
    return md_text


def fix_quotes(md_text: str) -> str:
    """Turn straight "..." into “...” outside code fences and code spans.

    pandoc smart quotes produce ``...'' which renders badly inside CJK runs;
    we fix the pairs ourselves and disable pandoc's smart conversion.
    """
    out_lines = []
    in_fence = False
    for ln in md_text.split("\n"):
        if ln.lstrip().startswith("```"):
            in_fence = not in_fence
            out_lines.append(ln)
            continue
        if in_fence:
            out_lines.append(ln)
            continue
        tokens = re.findall(r"``[^`]*``", ln)
        for k, t in enumerate(tokens):
            ln = ln.replace(t, f"\x00{k}\x00", 1)
        chars = []
        in_code = False
        open_quote = False
        for c in ln:
            if c == "`":
                in_code = not in_code
                chars.append(c)
                continue
            if c == '"' and not in_code:
                chars.append("“" if not open_quote else "”")
                open_quote = not open_quote
                continue
            chars.append(c)
        ln = "".join(chars)
        for k, t in enumerate(tokens):
            ln = ln.replace(f"\x00{k}\x00", t)
        out_lines.append(ln)
    return "\n".join(out_lines)


TIKZ_CAT = """```{=latex}
\\begin{center}
\\begin{tikzpicture}[node distance=3cm, auto]
  \\node (A) at (0,0) {$A$};
  \\node (B) at (3,0) {$B$};
  \\node (C) at (6,0) {$C$};
  \\draw[->] (A) -- node[above] {$f$} (B);
  \\draw[->] (B) -- node[above] {$g$} (C);
  \\draw[->] (A) edge[loop below, min distance=8mm] node[below] {$1_A$} (A);
  \\draw[->] (B) edge[loop below, min distance=8mm] node[below] {$1_B$} (B);
  \\draw[->] (C) edge[loop below, min distance=8mm] node[below] {$1_C$} (C);
\\end{tikzpicture}
\\end{center}

$g \\circ f\\colon A \\to C$ 表示先 $f$ 后 $g$。
```"""

TIKZ_CHAIN = """```{=latex}
\\begin{center}
\\begin{tikzpicture}[node distance=3cm, auto]
  \\node (A) at (0,0) {$A$};
  \\node (B) at (3,0) {$B$};
  \\node (C) at (6,0) {$C$};
  \\draw[->] (A) -- node[above] {$F$} (B);
  \\draw[->] (B) -- node[above] {$G$} (C);
  \\draw[->] (A) to [bend right=35] node[below] {$H$} (C);
\\end{tikzpicture}
\\end{center}
```"""


def replace_ascii_diagrams(md_text: str) -> str:
    """Replace ASCII commutative diagrams (plain fences with arrows) by TikZ."""

    def repl(m):
        body = m.group(1)
        if "------>" not in body:
            return m.group(0)
        if "1_A" in body:
            return TIKZ_CAT
        if "+---" in body:
            return TIKZ_CHAIN
        return m.group(0)

    return re.sub(r"```\n(.*?)```\n", repl, md_text, flags=re.S)


def unnumbered_references(tex: str) -> str:
    return tex.replace(
        r"\section{参考文献}",
        "\section*{参考文献}\n\\addcontentsline{toc}{section}{参考文献}",
    )


def tex_unicode_quotes(tex: str) -> str:
    """Replace pandoc's ``/'' quote markup with Unicode “ ” so the CJK font
    renders them directly (no ligature path, no engine-dependent glyphs)."""
    out = []
    in_listing = False
    for ln in tex.split("\n"):
        if "\\begin{lstlisting}" in ln:
            in_listing = True
            out.append(ln)
            continue
        if "\\end{lstlisting}" in ln:
            in_listing = False
            out.append(ln)
            continue
        if in_listing:
            out.append(ln)
            continue
        tokens = re.findall(r"\\lstinline![^!]*!", ln)
        for k, t in enumerate(tokens):
            ln = ln.replace(t, f"\x00{k}\x00", 1)
        ln = ln.replace("``", "“").replace("''", "”")
        for k, t in enumerate(tokens):
            ln = ln.replace(f"\x00{k}\x00", t)
        out.append(ln)
    return "\n".join(out)


TABLE_CAPTIONS = {
    # chapter -> [(label, caption, size)] in order of appearance; numbering
    # is automatic (表 N.M), captions above the table. size: "small" (default)
    # or "footnotesize" for dense tables.
    "ch01": [
        ("tab:1-1", "三种写法的对照", "small"),
        ("tab:1-2", "两类扩展的代价", "small"),
        ("tab:1-3", "C、Go、Scala、Haskell 的对照", "footnotesize"),
    ],
    "ch05": [
        ("tab:5-1", "五个例子的对照", "small"),
    ],
}


def style_tables(tex: str, captions) -> str:
    """Style every pandoc longtable: numbered caption (above), natural-width
    columns (l, no wrapping), no minipage cells, bold header row."""
    pattern = re.compile(
        r"\{\\def\\LTcaptype\{none\}.*?\\end\{longtable\}\n\}", re.S
    )
    blocks = list(pattern.finditer(tex))
    if len(blocks) != len(captions):
        raise SystemExit(
            f"table count mismatch: {len(blocks)} blocks, {len(captions)} captions"
        )
    for entry, m in reversed(list(zip(captions, blocks))):
        label, cap = entry[0], entry[1]
        size = entry[2] if len(entry) > 2 else "small"
        old = m.group(0)
        new = old.replace(
            r"\def\LTcaptype{none}",
            f"\\{size}\\setlength{{\\tabcolsep}}{{4pt}}\\def\\LTcaptype{{table}}",
            1,
        )
        # Natural-width left-aligned columns: no wrapping, not equal-width.
        # Each column is a group: >{\raggedright\arraybackslash}p{...}}
        new = re.sub(r">\{\\raggedright\\arraybackslash\}p\{[^}]*\}\}", "l", new)
        # Cells are plain text; pandoc's minipage wrappers only get in the way.
        new = new.replace("\\begin{minipage}[b]{\\linewidth}\\raggedright\n", "")
        new = new.replace("\\end{minipage}", "")
        # Bold header row (between \toprule and \midrule).
        new = re.sub(
            r"(?s)(\n\\toprule\\noalign\{\}\n)(.*?)( \\\\\n\\midrule\\noalign\{\}\n\\endhead)",
            lambda mm: mm.group(1)
            + " & ".join(
                f"\\textbf{{{c.strip()}}}" for c in mm.group(2).split(" & ")
            )
            + mm.group(3),
            new,
            count=1,
        )
        # Numbered caption + label, directly before the \toprule line.
        new = re.sub(
            r"(?m)^(\\toprule)",
            lambda mm: f"\\caption{{{cap}}}\\label{{{label}}}\\\\\n{mm.group(1)}",
            new,
            count=1,
        )
        tex = tex.replace(old, new, 1)
    return tex


def md_to_tex(md_text: str, out_path: Path) -> None:
    subprocess.run(
        [
            "pandoc",
            "-f", "markdown+tex_math_dollars+pipe_tables-smart",
            "-t", "latex",
            "--listings",
            "--top-level-division=chapter",
            "--wrap=preserve",
            "-o", str(out_path),
        ],
        input=md_text.encode("utf-8"),
        check=True,
    )


def build_fragments(meta) -> None:
    chapters_by_n = {c["n"]: c for c in meta["structure"]["chapters"]}
    for n in range(1, 22):
        ch = chapters_by_n[n]
        out = FRAG / f"ch{n:02d}.tex"
        if n in FULL_CHAPTERS:
            md = (SRC / ch["file"]).read_text(encoding="utf-8")
            md = strip_status(md)
            md = expand_includes(md, SRC)
            md = strip_heading_numbers(md)
            md = replace_ascii_diagrams(md)
            md = fix_quotes(md)
            md_to_tex(md, out)
            tex = tex_unicode_quotes(
                unnumbered_references(out.read_text(encoding="utf-8"))
            )
            if f"ch{n:02d}" in TABLE_CAPTIONS:
                tex = style_tables(tex, TABLE_CAPTIONS[f"ch{n:02d}"])
            out.write_text(tex, encoding="utf-8")
        else:
            out.write_text(
                f"% ch{n:02d}.tex -- 正文待写，目前只有章节标题。\n"
                f"\\chapter{{{ch['title']}}}\n",
                encoding="utf-8",
            )
        print(f"fragment: ch{n:02d}.tex")

    pref = (SRC / "preface.md").read_text(encoding="utf-8")
    pref = re.sub(r"^#\s*序\s*\n", "", pref)
    pref = fix_quotes(pref)
    md_to_tex(pref, FRAG / "preface.tex")
    (FRAG / "preface.tex").write_text(
        tex_unicode_quotes((FRAG / "preface.tex").read_text(encoding="utf-8")),
        encoding="utf-8",
    )
    print("fragment: preface.tex")


SYNOPSIS = r"""
本书面向会 Python、写过生产代码、却被 Haskell 类型系统与范畴论术语卡住的程序员。
它不把数学当作语言的背景知识，而是从能跑的代码倒推数学：每一章先给出一个写起来难看
的程序，再由它逼出一个概念。函子、应用函子、单子因此不再是名词，而是三个具体问题的
答案：给不同容器写同一套变换、把二元函数放进语境、三种效应共享一套复合规则。

全书分五个部分。语言部分用同一个求值器演示 Haskell 与其他语言的差异，并引入代数数据
类型与类型类；范畴与函子部分给出范畴的定义，核对 Hask 满足公理的范围，引入函子与自然
变换；应用函子部分把 Applicative 对应到数学上的 lax monoidal 函子，并巡礼六个实例；单子
部分处理 join 与 Kleisli 范畴；工程部分覆盖输入输出、包与测试、并发和一个完整实战。

本书与同类书的差别在于可验证：正文的每一段代码都来自可编译的工程，由测试与 CI 逐条
核对；数学与代码不一致处（如 $\bot$ 使 Hask 不满足单位律）不回避，明说结论成立的范围。
"""

PREAMBLE = r"""%!TEX program = lualatex
% 共享前导：latex/book.tex（正文）与 sample/sample.tex（样稿）共用。

\usepackage{amsmath,amssymb,amsthm,bm}
\usepackage{etoolbox}
\usepackage[left=3.2cm, right=3cm, top=3cm, bottom=3cm]{geometry}
\usepackage{booktabs,longtable,array}
\usepackage{calc}
\newcounter{none} % pandoc longtable without caption
\usepackage{graphicx,float}
\usepackage{enumerate,enumitem}
\usepackage[font=small]{caption}
\usepackage{xcolor}
\usepackage{tikz}
\usetikzlibrary{matrix,arrows,positioning,fit,calc}
\usepackage{listings}
\usepackage{fancyvrb}
\usepackage{newunicodechar}
\usepackage[unicode=true,pdfencoding=auto,psdextra,
  colorlinks=true,linkcolor=blue,urlcolor=blue]{hyperref}
\makeatletter
\g@addto@macro{\UrlBreaks}{\UrlOrds}
\def\input@path{{../latex/}{../latex/chapters/}{chapters/}}
\makeatother

\setlength{\parindent}{2em}

\providecommand{\tightlist}{%
  \setlength{\itemsep}{0pt}\setlength{\parskip}{0pt}}
\newcommand{\passthrough}[1]{#1}

\lstset{
  basicstyle=\ttfamily\small,
  breaklines=true,
  columns=flexible,
  keepspaces=true,
  showstringspaces=false,
  aboveskip=6pt,
  belowskip=6pt,
  frame=single,
  framesep=4pt,
  rulecolor=\color{black!30},
  keywordstyle=\color{blue!45!black}\bfseries,
  commentstyle=\color{black!45}\itshape,
  stringstyle=\color{red!55!black},
  literate={→}{{$\to$}}1 {←}{{$\leftarrow$}}1 {⇒}{{$\Rightarrow$}}1
           {≠}{{$\neq$}}1 {≥}{{$\geq$}}1 {≤}{{$\leq$}}1 {∈}{{$\in$}}1,
}

% Markers that have no glyph in the CJK fonts.
% 🦂 ◇ 📌 ✗ ⚠ render as color emoji via the emoji package (LuaLaTeX; Apple Color
% Emoji auto-detected).
\usepackage{emoji}
\newunicodechar{🦂}{\emoji{scorpion}}
\newunicodechar{◇}{\emoji{large-blue-diamond}}
\newunicodechar{✗}{\emoji{cross-mark}}
\newunicodechar{⚠}{\emoji{warning}}
\newunicodechar{📌}{\emoji{pushpin}}
\newunicodechar{→}{\textrightarrow}
\newunicodechar{←}{\textleftarrow}
\newunicodechar{⇒}{\ensuremath{\Rightarrow}}
\newunicodechar{≠}{\ensuremath{\neq}}
\newunicodechar{≥}{\ensuremath{\geq}}
\newunicodechar{≤}{\ensuremath{\leq}}
\newunicodechar{∈}{\ensuremath{\in}}
\newunicodechar{∅}{\ensuremath{\varnothing}}
\newunicodechar{μ}{\ensuremath{\mu}}
\newunicodechar{λ}{\ensuremath{\lambda}}
"""

FRONT = r"""\chapter*{内容简介}
\addcontentsline{toc}{chapter}{内容简介}

""" + SYNOPSIS + r"""

\chapter*{序}
\addcontentsline{toc}{chapter}{序}

\input{chapters/preface}
"""


def build_main(meta) -> None:
    lines = []
    for p in meta["structure"]["parts"]:
        lines.append(r"\part{%s}" % p["title"])
        for n in p["chapters"]:
            lines.append(r"\input{chapters/ch%02d}" % n)
    (LATEX / "book-main.tex").write_text("\n\n".join(lines) + "\n", encoding="utf-8")


BOOK_TEX = r"""%!TEX program = lualatex
% 正文主文件。样稿见 ../sample/sample.tex（与正文的唯一区别是样稿标记页）。
\documentclass[11pt,a4paper,fontset=fandol]{ctexbook}

\input{book-preamble}

\begin{document}

\begin{titlepage}
  \centering
  \vspace*{3.2cm}
  {\Large\bfseries 边学 Haskell 边学范畴论\par}
  \vspace{0.4cm}
  {\large\bfseries 从可运行的代码反推数学\par}
  \vspace{1.2cm}
  {\large 宋丛威\par}
\end{titlepage}

\frontmatter
\input{front}
\tableofcontents

\mainmatter
\setcounter{secnumdepth}{3}
\input{book-main}

\end{document}
"""

SAMPLE_TEX = r"""%!TEX program = lualatex
% 样稿：与正文（latex/book.tex）共用前导、前件与章节文件，
% 唯一区别是样稿标题页与样稿说明。
\documentclass[11pt,a4paper,fontset=fandol]{ctexbook}

\input{../latex/book-preamble}

\begin{document}

\begin{titlepage}
  \centering
  \vspace*{3.2cm}
  {\Large\bfseries 边学 Haskell 边学范畴论\par}
  \vspace{0.4cm}
  {\large\bfseries 从可运行的代码反推数学\par}
  \vspace{1.2cm}
  {\large 宋丛威\par}
  \vspace{2.2cm}
  {\large 样稿\par}
  \vspace{0.4cm}
  {\normalsize 内容简介 $\cdot$ 序 $\cdot$ 目录 $\cdot$ 第一章 $\cdot$ 第五章（全文）$\cdot$ 其余章节（仅标题）\par}
  \vspace{1.2cm}
  {\small 供编辑与评审审阅\par}
\end{titlepage}

\frontmatter

\chapter*{样稿说明}
\addcontentsline{toc}{chapter}{样稿说明}

本册为《边学 Haskell 边学范畴论》的样稿，供编辑与评审参考。样稿与正式版正文的唯一区别
是本说明与样稿标题页；正文取自正式版对应章节，未作删改。样稿包含内容简介、序、目录、
第一章与第五章的全文；其余章节在目录中列出标题，正文从略。

\input{../latex/front}
\tableofcontents

\mainmatter
\setcounter{secnumdepth}{3}
\input{../latex/book-main}

\end{document}
"""


def compile(main: Path, cwd: Path, label: str) -> Path:
    for _ in range(2):
        r = subprocess.run(
            ["lualatex", "-interaction=nonstopmode", "-halt-on-error", str(main.name)],
            cwd=cwd,
            capture_output=True,
            text=True,
        )
        if r.returncode != 0:
            log = (cwd / (main.stem + ".log")).read_text(encoding="utf-8")
            print(f"{label} FAILED\n" + "\n".join(log.splitlines()[-40:]))
            raise SystemExit(1)
    pdf = cwd / (main.stem + ".pdf")
    print(f"{label}: {pdf}")
    return pdf


def main() -> None:
    meta = json.loads((ROOT / "book.meta.json").read_text(encoding="utf-8"))
    build_fragments(meta)
    (LATEX / "book-preamble.tex").write_text(PREAMBLE, encoding="utf-8")
    (LATEX / "front.tex").write_text(FRONT, encoding="utf-8")
    build_main(meta)
    (LATEX / "book.tex").write_text(BOOK_TEX, encoding="utf-8")
    (SAMPLE / "sample.tex").write_text(SAMPLE_TEX, encoding="utf-8")

    compile(LATEX / "book.tex", LATEX, "book.pdf")
    pdf = compile(SAMPLE / "sample.tex", SAMPLE, "sample.pdf")
    dest = SAMPLE / "样稿.pdf"
    shutil.copy(pdf, dest)
    print(f"样稿.pdf: {dest}")
    print("DONE")


if __name__ == "__main__":
    main()
