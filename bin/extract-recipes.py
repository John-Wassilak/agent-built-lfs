#!/usr/bin/env python3
"""Extract per-package command blocks from the chunked LFS book into candidate recipes.

Output is a *candidate* only. Every recipe is reviewed against the book prose before it
runs -- the book contains optional blocks (test suites, alternative configure lines,
"if you want X" branches) that must not be concatenated blindly. Blocks inside an
admonition (note/tip/caution/warning) or inside a test-suite section are emitted
commented out and tagged, so review is a matter of reading the tags.

The unpack / cd / cleanup wrapper described in the book's General Instructions is NOT
extracted; the driver supplies it. Recipes contain only in-package commands.
"""

import html
import json
import os
import re
import sys
from html.parser import HTMLParser

BOOK = "/home/john/lfs/book/13.0"
OUT = "/home/john/lfs/recipes"
OVERRIDES = "/home/john/lfs/recipes/review-overrides.json"

ADMON = re.compile(r"\badmon\b")
WS = re.compile(r"\s+")


class PageParser(HTMLParser):
    """Walk a package page, capturing userinput <pre> blocks with their context."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.div_stack = []          # class attr of each open <div>
        self.blocks = []             # captured command blocks
        self.title = None
        self.in_pre = None           # 'userinput' | 'screen' | None
        self.buf = []
        self.text_buf = []           # rolling prose, for block context
        self.in_title = False
        self.sect_stack = []         # nearest section headings

    # --- tag tracking -----------------------------------------------------
    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        cls = a.get("class", "")
        if tag == "div":
            self.div_stack.append(cls)
        elif tag == "pre":
            self.in_pre = "userinput" if "userinput" in cls else "screen"
            self.buf = []
        elif tag == "h1" and "sect1" in cls and self.title is None:
            self.in_title = True
            self.text_buf = []

    def handle_endtag(self, tag):
        if tag == "div":
            if self.div_stack:
                self.div_stack.pop()
        elif tag == "pre":
            if self.in_pre == "userinput":
                cmd = "".join(self.buf).strip("\n")
                if cmd.strip():
                    self.blocks.append(
                        {
                            "cmd": cmd,
                            "admon": self._admon(),
                            "divs": [d for d in self.div_stack if d],
                            "context": self._context(),
                        }
                    )
            self.in_pre = None
            self.buf = []
            self.text_buf = []
        elif tag == "h1" and self.in_title:
            self.title = WS.sub(" ", "".join(self.text_buf)).strip()
            self.in_title = False
            self.text_buf = []

    def handle_data(self, data):
        if self.in_pre == "userinput":
            self.buf.append(data)
        elif self.in_pre == "screen":
            pass
        else:
            self.text_buf.append(data)
            if len(self.text_buf) > 400:
                del self.text_buf[:-400]

    # --- helpers ----------------------------------------------------------
    def _admon(self):
        """Nearest enclosing admonition class, if any."""
        for cls in reversed(self.div_stack):
            if ADMON.search(cls):
                return cls.replace("admon", "").strip() or "admon"
        return None

    def _context(self):
        t = WS.sub(" ", "".join(self.text_buf)).strip()
        return t[-400:]


# Classification is STRUCTURAL, not prose-based.
#
# An earlier version keyed off the surrounding prose ("test suite", "known to fail").
# That was actively dangerous: in the book the test-suite paragraph sits immediately
# before "Install the package: make install", so 27 mandatory install commands --
# including gcc's and binutils' -- inherited the hint and were silently disabled.
#
# Two rules now, both structural:
#   1. the command IS a test invocation  -> disabled (tests are opt-in per package)
#   2. the block sits inside an admonition -> flagged for review (small, reviewable set)
# Everything else is a book instruction and is enabled.

TEST_CMD = re.compile(
    r"""^\s*(
          make\s+(-k\s+)?(-C\s+\S+\s+)?(check|tests?)\b
        | make\s+.*\b(check|tests?)\b
        | ninja\s+tests?\b
        | meson\s+tests?\b
        | ctest\b
        | \./?config\S*\s+test\b
        )""",
    re.X,
)

def classify(block, page):
    """Return (enabled, tags) using structural signals only."""
    tags = []
    first = (block["cmd"].splitlines() or [""])[0]

    if block["admon"]:
        tags.append(f"admon:{block['admon']}")
    if TEST_CMD.match(first):
        tags.append("testsuite")

    return (not tags), tags


def load_overrides():
    """Review decisions persist here, so re-extraction never clobbers them."""
    try:
        raw = json.load(open(OVERRIDES))
    except FileNotFoundError:
        return {}
    return {k: v for k, v in raw.items() if not k.startswith("_")}


QUEUE = []


def main():
    os.makedirs(OUT, exist_ok=True)
    overrides = load_overrides()
    index = []
    pages = sorted(
        p
        for p in (
            os.path.join(d, f)
            for d, _, fs in os.walk(BOOK)
            for f in fs
            if f.endswith(".html")
        )
        if re.search(r"/chapter(0[4-9]|1[01])/", p)
    )

    for path in pages:
        base = os.path.basename(path)[:-5]
        chap = re.search(r"chapter(\d\d)", path).group(1)
        if base in ("chapter" + chap, "introduction"):
            continue
        src = open(path, encoding="utf-8", errors="replace").read()
        p = PageParser()
        p.feed(src)
        if not p.blocks:
            continue

        name = f"ch{chap}-{base}"
        n_on = 0
        lines = [
            "#!/bin/bash",
            "# CANDIDATE recipe extracted from the LFS 13.0-systemd book.",
            f"# source : book/13.0/chapter{chap}/{base}.html",
            f"# title  : {p.title}",
            "# The driver supplies unpack/cd/cleanup. Commands below are in-package only.",
            "# Disabled blocks are tagged with the reason; review before enabling.",
            "set -e",
            "",
        ]
        ov = overrides.get(name, {})
        for i, b in enumerate(p.blocks):
            enabled, tags = classify(b, base)
            decision = ov.get(str(i))
            if decision:
                act = decision["action"]
                if act in ("drop", "defer"):
                    enabled = False
                    tags = [f"REVIEWED:{act}"]
                elif act == "enable":
                    enabled = True
                    tags = []
                elif act == "replace":
                    enabled = True
                    tags = []
                    b["cmd"] = decision["cmd"]
                elif act == "test" and os.environ.get("LFSBUILD_SKIP_TESTS"):
                    enabled = False
                    tags = ["REVIEWED:test-skipped-this-run"]
                elif act == "test":
                    # Critical test suites run, but a documented failure must not abort
                    # the build. Exit status is recorded in the log for comparison.
                    enabled = True
                    tags = []
                    b["cmd"] = (
                        "set +e\n" + b["cmd"] +
                        f"\n__rc=$?\nset -e\n"
                        f'echo "### TESTSUITE {name} block {i} exit=$__rc '
                        f'(non-fatal, compare against book)"'
                    )
            n_on += enabled
            lines.append(f"# --- block {i} " + ("-" * 50))
            if b["context"]:
                for cl in re.findall(r".{1,88}(?:\s|$)", b["context"]):
                    if cl.strip():
                        lines.append(f"#   ctx: {cl.strip()}")
            if tags and not decision:
                QUEUE.append({
                    "recipe": name, "block": i, "tags": tags,
                    "cmd": b["cmd"], "context": b["context"],
                })
            if tags:
                if decision:
                    lines.append(f"#   REVIEWED [{decision['action']}]: {decision['reason']}")
                else:
                    lines.append(f"#   TAGS: {' '.join(tags)}   [DISABLED - review]")
                lines.extend("# " + l for l in b["cmd"].splitlines())
            else:
                lines.append(b["cmd"])
            lines.append("")

        with open(os.path.join(OUT, name + ".sh"), "w") as f:
            f.write("\n".join(lines) + "\n")

        index.append(
            {
                "name": name,
                "chapter": chap,
                "page": base,
                "title": p.title,
                "blocks": len(p.blocks),
                "enabled": n_on,
                "disabled": len(p.blocks) - n_on,
                "reviewed": len(ov),
            }
        )

    with open(os.path.join(OUT, "index.json"), "w") as f:
        json.dump(index, f, indent=2)

    with open(os.path.join(OUT, "review-queue.json"), "w") as f:
        json.dump(QUEUE, f, indent=2)

    print(f"{len(index)} recipes -> {OUT}")
    tot = sum(i["blocks"] for i in index)
    dis = sum(i["disabled"] for i in index)
    rev = sum(i["reviewed"] for i in index)
    print(f"blocks: {tot} total, {tot - dis} enabled, {dis} disabled")
    print(f"review decisions applied: {rev}")


if __name__ == "__main__":
    main()
