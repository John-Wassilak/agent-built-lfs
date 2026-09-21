#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# agent-built-lfs -- shared book-page parsing/classification/rendering
# Copyright (c) 2026 John Wassilak

"""Machinery shared by every per-book extractor in bin/.

Pulled out of extract-recipes.py (which used to define all of this for LFS alone, and
was imported by extract-blfs.py via importlib for BLFS's reuse) once a third and fourth
book family -- SLFS and GLFS, onboarded 2026-09-07 -- needed the exact same page-parsing
and block-classification logic pointed at a different book/<family>-<version>/
directory. extract-recipes.py keeps its own whole-book chapter walk (LFS chapters 4-11
are extracted wholesale); extract-blfs.py, extract-slfs.py and extract-glfs.py are all
driven by a host's packages.py list instead, and share run_family_extraction() below.

Admonition detection: LFS/BLFS's book-build marks an admonition div "admon note" (two
class tokens). SLFS/GLFS's own online pages (there is no downloadable pre-built chunked
HTML for either -- see README.md) mark the same thing "note" (one token, no "admon").
Checked directly against real pages of both: LFS 13.1/BLFS 13.1 never have a bare
admonition-word class without "admon" alongside it, so matching on either convention is
a strict superset with no effect on LFS/BLFS output.
"""

import json
import os
import re
import sys
from html.parser import HTMLParser

ADMON = re.compile(r"\badmon\b")
ADMON_WORDS = {"note", "tip", "caution", "warning", "important"}
WS = re.compile(r"\s+")

# Path (relative to the repo root) to a family's chunked-HTML book, keyed by the
# version a host's host.toml [books] table pins for that family.
BOOK_DIR = {
    "lfs": "book/{ver}",
    "blfs": "book/blfs-{ver}",
    "slfs": "book/slfs-{ver}",
    "glfs": "book/glfs-{ver}",
}


def book_root(root, host, family):
    """Path to `family`'s chunked-HTML book directory at this host's pinned version."""
    return os.path.join(root, BOOK_DIR[family].format(ver=host.books[family]))


def require_book(root, book_dir, family):
    """The book is gitignored, so a fresh clone does not have it. Without this guard an
    extraction is a silent no-op that overwrites the recipe index with an empty list."""
    if not os.path.isdir(book_dir):
        sys.exit(f"no {family.upper()} book at {os.path.relpath(book_dir, root)} -- it "
                 f"is not tracked in this repository. See README.md, 'Getting the books'.")


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
        """Nearest enclosing admonition class, if any -- either book-build convention
        ("admon note") or SLFS/GLFS's own online-page convention ("note" alone)."""
        for cls in reversed(self.div_stack):
            if ADMON.search(cls):
                return cls.replace("admon", "").strip() or "admon"
            tokens = set(cls.split())
            hit = tokens & ADMON_WORDS
            if hit:
                return " ".join(sorted(hit))
        return None

    def _context(self):
        t = WS.sub(" ", "".join(self.text_buf)).strip()
        return t[-400:]


class RootAndUserinputPageParser(PageParser):
    """BLFS/SLFS/GLFS mark root-only commands with <pre class="root">, and that is
    where every `make install` lives. The base parser only captures class="userinput",
    which would silently drop the install step from every one of these recipes. Capture
    both, in document order, and record which class each came from -- inside the chroot
    we are root either way."""

    def handle_starttag(self, tag, attrs):
        if tag == "pre":
            cls = dict(attrs).get("class", "")
            if "userinput" in cls or "root" in cls:
                self.in_pre = "userinput"
            else:
                self.in_pre = "screen"
            self.buf = []
            return
        super().handle_starttag(tag, attrs)


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


def render_body(name, parsed, decisions, queue):
    """The per-block loop shared by every book family: apply reviewed decisions on top
    of structural classification, render enabled/disabled/reviewed text, queue anything
    tagged-but-undecided. Returns (lines, n_on) -- callers prepend their own header
    (book label and version differ per family; the body does not).
    """
    n_on = 0
    lines = []
    for i, b in enumerate(parsed.blocks):
        cmd = b["cmd"]
        enabled, tags = classify(b, name)
        decision = decisions.get(str(i))
        if decision:
            act = decision["action"]
            if act in ("drop", "defer"):
                enabled, tags = False, [f"REVIEWED:{act}"]
            elif act == "enable":
                enabled, tags = True, []
            elif act == "replace":
                enabled, tags = True, []
                cmd = decision["cmd"]
            elif act == "test" and os.environ.get("LFSBUILD_SKIP_TESTS"):
                enabled, tags = False, ["REVIEWED:test-skipped-this-run"]
            elif act == "test":
                # Critical test suites run, but a documented failure must not abort
                # the build. Exit status is recorded in the log for comparison.
                enabled, tags = True, []
                cmd = (
                    "set +e\n" + cmd +
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
        if tags and not decision and queue is not None:
            queue.append({"recipe": name, "block": i, "tags": tags,
                          "cmd": cmd, "context": b["context"]})
        if tags:
            if decision:
                lines.append(f"#   REVIEWED [{decision['action']}]: {decision['reason']}")
            else:
                lines.append(f"#   TAGS: {' '.join(tags)}   [DISABLED - review]")
            lines.extend("# " + l for l in cmd.splitlines())
        else:
            lines.append(cmd)
        lines.append("")

    return lines, n_on


def hand_owned_shared(lfshost, family):
    """Steps that some host declares hand() and whose recipe is the SHARED one.

    Returns {step: [host, ...]}. These files belong to a human, and the extractors must
    never write them -- not even when a different host declares the same package as a
    book() step, which is the case this exists for.

    recipes/ is shared by every machine while packages.py is per-machine, so the two can
    disagree: `server` declares hand(226, "imagemagick", ...) and owns the comments in
    recipes/blfs-imagemagick.sh, and a book(334, "imagemagick", "general/imagemagick.html",
    ...) added to `laptop` made the extractor the owner of that same filename and rewrite
    it (2026-09-15). Nothing in the per-host view could see the conflict, because the
    other host's entry is not in this host's plan. Only reading every packages.py can.

    A hand() step whose recipe is host-scoped (hosts/<h>/recipes/<step>.sh exists) is not
    included: that file is unreachable from any other machine, so the shared path is free.
    """
    owners = {}
    for name in lfshost.known():
        try:
            h = lfshost.Host(name)
            pkgs = lfshost.packages(h)
        except Exception as exc:
            print(f"warning: cannot read hosts/{name}/packages.py ({exc}) -- its "
                  f"hand-authored recipes are NOT protected in this run", file=sys.stderr)
            continue
        for p in pkgs:
            if p["html"] or p.get("family", "blfs") != family:
                continue
            step = f"{family}-{p['name']}"
            if not lfshost.recipe_is_host(h, step):
                owners.setdefault(step, []).append(name)
    return owners


def run_family_extraction(root, lfshost, host, family, page_parser_cls, header,
                          overrides_file, check=False):
    """Shared driver for a book family whose steps come from a host's packages.py list
    (BLFS/SLFS/GLFS all share this shape; LFS's whole-book chapter walk in
    extract-recipes.py does not and keeps its own main()).

    `header(step, page_path, version, title)` -> list of header lines (the "#!/bin/bash"
    block down through "set -e"), letting each family keep its own exact banner text and
    source-path convention. `lfshost` is the already-imported lfshost module (passed in
    rather than imported here to keep this module import-order-agnostic).

    Returns (plan, queue, problems, drift, new) -- callers decide what to print and
    whether to write host.<family>_plan / <family>-review-queue.json.
    """
    book_dir = book_root(root, host, family)
    require_book(root, book_dir, family)

    packages = lfshost.packages(host)
    shared_dec = lfshost.overrides(host, overrides_file, layer="shared")
    merged_dec = lfshost.overrides(host, overrides_file, layer="merged")
    host_pages = lfshost.host_override_pages(host, overrides_file)
    hand_owned = hand_owned_shared(lfshost, family)

    out = f"{root}/recipes"
    ver = host.books[family]
    plan, queue, problems, drift, new = [], [], [], [], []

    for p in packages:
        if p.get("family", "blfs") != family:
            continue
        step = f"{family}-{p['name']}"

        if p["html"]:
            if step in hand_owned:
                others = ", ".join(f"'{h}'" for h in hand_owned[step])
                problems.append(
                    f"{step}: declared book() here, but {others} declare(s) it hand() "
                    f"and its recipe is the shared recipes/{step}.sh. Generating it "
                    f"would overwrite a hand-authored file. Declare it hand() here too, "
                    f"or convert the other host(s) to book() and move the recipe's "
                    f"comments into that host's BUILD-REPORT.md.")
                continue
            path = os.path.join(book_dir, p["html"])
            if not os.path.exists(path):
                problems.append(f"{step}: no book page at "
                                f"{os.path.relpath(book_dir, root)}/{p['html']}")
                continue
            parsed = page_parser_cls()
            parsed.feed(open(path, encoding="utf-8", errors="replace").read())

            body, n_on = render_body(step, parsed, shared_dec.get(step, {}), queue)
            text = "\n".join(header(step, p["html"], ver, parsed.title) + body) + "\n"
            shared_path = f"{out}/{step}.sh"
            if check:
                if not os.path.exists(shared_path):
                    new.append(step)
                elif open(shared_path).read() != text:
                    drift.append(step)
            else:
                with open(shared_path, "w") as f:
                    f.write(text)

            if step in host_pages:
                hbody, n_on = render_body(step, parsed, merged_dec.get(step, {}), None)
                htext = "\n".join(header(step, p["html"], ver, parsed.title) + hbody) + "\n"
                host_path = f"{host.recipes}/{step}.sh"
                if check:
                    rel = os.path.relpath(host_path, root)
                    if not os.path.exists(host_path):
                        new.append(rel)
                    elif open(host_path).read() != htext:
                        drift.append(rel)
                else:
                    os.makedirs(host.recipes, exist_ok=True)
                    with open(host_path, "w") as f:
                        f.write(htext)

            title = parsed.title
            blocks, enabled, disabled = len(parsed.blocks), n_on, len(parsed.blocks) - n_on
            kind = "host" if step in host_pages else "book"
        else:
            recipe = lfshost.recipe(host, step)
            if not os.path.exists(recipe):
                problems.append(f"{step}: hand-authored, but no recipe at "
                                f"{os.path.relpath(recipe, root)}")
                continue
            title = p["title"]
            blocks, enabled, disabled = p["blocks"] or 1, 1, 0
            kind = "hand*" if lfshost.recipe_is_host(host, step) else "hand"

        plan.append({
            "seq": p["seq"], "order": f"{family}.{p['seq']}", "name": step,
            "chapter": family, "page": p["page"], "title": title,
            "context": "chroot", "tarball": p["tarball"], "manifest": True,
            "blocks": blocks, "enabled": enabled, "disabled": disabled,
        })
        print(f"  {step:26} {kind:5} {blocks:2} blocks, {enabled:2} enabled, "
              f"{disabled:2} disabled   {title}")

    return plan, queue, problems, drift, new
