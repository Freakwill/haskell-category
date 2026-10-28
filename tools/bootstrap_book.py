#!/usr/bin/env python3
"""Generate the mdBook skeleton for 《边学 Haskell 边学范畴论》.

Idempotent: refuses to overwrite an existing chapter file, so hand-written
prose is never clobbered. Run from anywhere:

    python3 tools/bootstrap_book.py
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"

# (part, number, slug, title, target_wan, focus)
CHAPTERS = [
    ("第一部分 语言", 1, "ch01-python-to-haskell", "从 Python 到 Haskell：表达式、类型、求值", "1.2",
     "惰性求值与副作用的第一印象；不要写成语言手册"),
    ("第一部分 语言", 2, "ch02-functions", "函数、递归、高阶函数、柯里化", "1.3",
     "柯里化为第 8 章的 curry / 笛卡尔闭范畴埋线"),
    ("第一部分 语言", 3, "ch03-data", "代数数据类型与模式匹配", "1.3",
     "data 与和/积类型的对应，为第 5 章的积与余积预热"),
    ("第一部分 语言", 4, "ch04-typeclass", "类型类：ad-hoc 多态", "1.4",
     "类型类不是接口；deriving 与定律的关系"),
    ("第二部分 范畴与函子", 5, "ch05-category", "范畴：对象、态射、复合、函子", "1.5",
     "从零建立记号；一个范畴的四个条件要配四张图"),
    ("第二部分 范畴与函子", 6, "ch06-hask", "Hask：把类型系统当范畴看", "1.4",
     "诚实处理 seq 与 ⊥ 导致的 Hask 不成立"),
    ("第二部分 范畴与函子", 7, "ch07-functor", "函子与自然变换：fmap 与自然性", "1.8",
     "样章之一；自然性方块必须手画 TikZ"),
    ("第三部分 应用函子", 8, "ch08-applicative", "从函子到应用函子：笛卡尔闭范畴与 lax monoidal", "1.7",
     "Applicative ≈ lax monoidal functor，本书的拉开距离之处"),
    ("第三部分 应用函子", 9, "ch09-applicative-tour", "实例巡礼：Maybe / List / Reader / Const / ZipList / Validation", "1.4",
     "Const 与 Monoid；ZipList 的 pure 是 repeat 的理由"),
    ("第四部分 单子", 10, "ch10-monad", "单子（一）：join / μ 与 >>= 的等价", "1.7",
     "等价性证明要写成人能读的，不是交换图堆砌"),
    ("第四部分 单子", 11, "ch11-kleisli", "单子（二）：Kleisli 范畴、自函子范畴的幺半群、半群作用", "1.8",
     "样章之一；半群视角是本书独有资产，需请数学同行复核"),
    ("第四部分 单子", 12, "ch12-monad-tour", "实例巡礼：State / Reader / Writer / Except / IO / ST", "1.7",
     "IO 的 RealWorld 只能当直觉，需明说真实实现是 State# RealWorld"),
    ("第四部分 单子", 13, "ch13-transformer", "Monad Transformer 与 mtl", "1.4",
     "不讲变换器，读者写出第三个叠加效应就会崩"),
    ("第五部分 工程", 14, "ch14-package", "模块、包、cabal、测试与文档", "1.4",
     "要写成能照着做完的流水线，不是命令清单"),
    ("第五部分 工程", 15, "ch15-concurrency", "并发与并行：async、STM、par", "1.3",
     "STM 的 retry 最能体现函数式的优势"),
    ("第五部分 工程", 16, "ch16-project", "实战：写一个解析器与一个小服务", "1.7",
     "megaparsec + servant，全书收口；贯穿项目在这里成形"),
]

APPENDICES = [
    ("appendix-a-math", "附录 A 数学补遗：集合、态射、自然变换的标准定义", "0.6"),
    ("appendix-b-solutions", "附录 B 习题答案（A 类全给，B / C 类给提示）", "1.0"),
    ("appendix-c-glossary", "附录 C 中英术语对照", "0.4"),
    ("appendix-d-toolchain", "附录 D 工具链与版本矩阵", "0.2"),
]

BOOK_TOML = """[book]
title = "边学 Haskell 边学范畴论"
authors = ["宋丛威"]
language = "zh-CN"
description = "从可运行的代码倒推范畴论：函子、应用函子、单子，以及它们的工程落地。"
src = "src"

[build]
build-dir = "site"
create-missing = false

[output.html]
default-theme = "light"
preferred-dark-theme = "navy"
mathjax-support = true
site-url = "/haskell-category/"
git-repository-url = "https://github.com/Freakwill/haskell-category"
edit-url-template = "https://github.com/Freakwill/haskell-category/edit/main/src/{path}"
no-section-label = true
additional-css = ["theme/book.css"]
"""

CSS = """/* 中文正文的可读性调整；代码块与正文分开字体 */
:root {
  --code-font: "JetBrains Mono", "SF Mono", Menlo, Consolas, monospace;
}
.content {
  font-family: "PingFang SC", "Noto Sans CJK SC", "Source Han Sans SC", system-ui, sans-serif;
  line-height: 1.85;
  font-size: 1.6rem;
}
.content p { text-indent: 2em; }
.content li p, .content blockquote p, .content td p { text-indent: 0; }
.content h1, .content h2, .content h3 { text-indent: 0; }
code { font-family: var(--code-font); }
pre code { line-height: 1.55; }
.content table { font-size: 1.5rem; }
"""


def chapter_stub(num: int, title: str, slug: str, target: str, focus: str) -> str:
    module = f"Ch{num:02d}"
    return f"""# {title}

> **状态**：待写 ｜ **目标**：{target} 万字 ｜ **代码**：`code/src/{module}/`
>
> 写作提示：{focus}

## {num}.1 问题

<!-- 一个能跑的小程序，暴露"没有这个概念就写不下去"。先有问题，再有定义。 -->

## {num}.2 数学

<!-- 定义 + 一句直觉。完整证明放 ◇ 框，长推导挪到附录 A。 -->

## {num}.3 代码

<!-- 代码不手抄。在 code/src/{module}/ 里写好并用 ANCHOR 标记，
     这里用 {{#include ../../code/src/{module}/Basics.hs:anchor-name}} 引入。 -->

## {num}.4 陷阱

<!-- 3–5 条，贴真实的 GHC 报错原文。 -->

## {num}.5 练习

- **A 改写**：
- **B 证明**：
- **C 造实例**：

## {num}.6 延伸

- 数学：
- 工程：
"""


def appendix_stub(title: str, target: str) -> str:
    return f"""# {title}

> **状态**：待写 ｜ **目标**：{target} 万字

<!-- 提纲先行，正文后补。 -->
"""


def summary_md() -> str:
    lines = ["# Summary", "", "[序](preface.md)", ""]
    part = None
    for p, num, slug, title, _t, _f in CHAPTERS:
        if p != part:
            part = p
            lines += [f"# {p}", ""]
        lines.append(f"- [{title}]({slug}.md)")
    lines += ["", "# 附录", ""]
    for slug, title, _t in APPENDICES:
        lines.append(f"- [{title}]({slug}.md)")
    lines.append("")
    return "\n".join(lines)


PREFACE = """# 序

这本书想解决一个具体的困境：你能写 Python，也听说过 monad，看过几篇讲范畴论的博客，
但这两件事在你脑子里始终是分开的——数学是数学，代码是代码。

我的写法是**从能跑的代码倒推数学**，而不是从定义推向代码。每一章都先有一个跑不起来、
或者写起来极其难看的程序，再由它逼出一个概念。第 7 章的函子是从"给一堆不同的容器写
同一套变换函数"逼出来的；第 11 章的单子是从"三种不同的效应居然共享同一套复合规则"
逼出来的。

## 怎么读

- **数学恐惧症**：标 ◇ 的段落都可以跳过，只读定义和代码。全书正文只保留"足以看懂代码"
  的数学。
- **只想学 Haskell**：第 1–4 章、第 14–16 章是一条完整的工程路径，中间三部分当参考手册。
- **只想学范畴论**：第 5、7、8、10、11 章是主线，代码当例子看。

## 约定

- 代码全部来自 `code/` 里可编译的工程，正文里的每一段都能在仓库里找到并跑通。
- 术语首次出现给英文原文，全书中英对照见附录 C。
- 版本：GHC 9.14 / cabal 3.18，见附录 D。

本书在线版的源码在 <https://github.com/Freakwill/haskell-category>，
勘误与新章节都在那里。
"""


def main() -> None:
    SRC.mkdir(exist_ok=True)
    (ROOT / "theme").mkdir(exist_ok=True)
    (ROOT / "book.toml").write_text(BOOK_TOML, encoding="utf-8")
    (ROOT / "theme" / "book.css").write_text(CSS, encoding="utf-8")

    created, skipped = [], []
    for path, text in [(SRC / "preface.md", PREFACE)]:
        if path.exists():
            skipped.append(path.name)
        else:
            path.write_text(text, encoding="utf-8")
            created.append(path.name)

    for p, num, slug, title, target, focus in CHAPTERS:
        path = SRC / f"{slug}.md"
        if path.exists():
            skipped.append(path.name)
            continue
        path.write_text(chapter_stub(num, title, slug, target, focus), encoding="utf-8")
        created.append(path.name)

    for slug, title, target in APPENDICES:
        path = SRC / f"{slug}.md"
        if path.exists():
            skipped.append(path.name)
            continue
        path.write_text(appendix_stub(title, target), encoding="utf-8")
        created.append(path.name)

    summary = SRC / "SUMMARY.md"
    if summary.exists():
        skipped.append("SUMMARY.md")
    else:
        summary.write_text(summary_md(), encoding="utf-8")
        created.append("SUMMARY.md")

    total = sum(float(c[4]) for c in CHAPTERS)
    print(f"created {len(created)}: {', '.join(created) if created else '-'}")
    print(f"skipped {len(skipped)}: {', '.join(skipped) if skipped else '-'}")
    print(f"chapters: {len(CHAPTERS)}, target words: {total:.1f} 万")


if __name__ == "__main__":
    main()
