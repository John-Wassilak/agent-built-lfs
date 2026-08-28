"""The BLFS steps every machine in this repo needs, in build order.

This is the closure of "an LFS system you can actually work on": a CA store so TLS
works at all, Node.js for Claude Code, ssh in and out, curl/wget/git, sudo, and a
firewall. Nothing here depends on a GPU, a display, a disk layout or a CPU vendor --
that is the test for whether an entry belongs in this file or in a host's.

A host's packages.py imports BASE and appends its own stack:

    from base import BASE, book, hand
    PACKAGES = BASE + [ ... ]

Two kinds of entry, because a BLFS build has two kinds of step:

  book(seq, name, html, tarball)
        The recipe is extracted from that BLFS page by bin/extract-blfs.py, with review
        decisions applied from recipes/blfs-overrides.json plus the host's own.

  hand(seq, name, tarball, title)
        No book page covers it (a proprietary driver, a Go program, a font tarball, a
        package BLFS does not carry). The recipe is a hand-authored file in recipes/ or
        hosts/<h>/recipes/ and the extractor validates it exists but never writes it.

`seq` is explicit and permanent, not a position in this list. Gaps are real history: a
missing number is a step that was planned, given a number, and then dropped -- the
abandoned Wayland/Hyprland tier is the reason for most of `server`'s gaps. New steps
take the next unused number. Keep the list sorted by seq; that is the build order.
"""


def book(seq, name, html, tarball, *, page=None):
    """A step whose recipe is extracted from a BLFS book page.

    `html` is the path under book/blfs-13.0/. `page` is the book page's short label and
    defaults to the step name; it differs only where one page installs several packages
    (x7lib, TTF-and-OTF-fonts).
    """
    return {"seq": seq, "name": name, "page": page or name, "html": html,
            "tarball": tarball, "title": None, "blocks": None}


def hand(seq, name, tarball, title, *, page=None):
    """A step whose recipe is hand-authored and lives in the tree.

    The extractor validates the recipe exists and puts the step in the plan; it never
    writes the file. That is what makes editing one safe, and it is the right answer for
    any recipe whose real content is not derivable from a book page plus a review
    decision -- including recipes that started as book extractions and were then tuned.
    """
    return {"seq": seq, "name": name, "page": page or name, "html": None,
            "tarball": tarball, "title": title, "blocks": 1}


BASE = [
    book(1, "which", "general/which.html", "which-2.23.tar.gz"),
    book(2, "libtasn1", "general/libtasn1.html", "libtasn1-4.21.0.tar.gz"),
    book(3, "p11-kit", "postlfs/p11-kit.html", "p11-kit-0.26.2.tar.xz"),
    book(4, "make-ca", "postlfs/make-ca.html", "make-ca-1.16.1.tar.gz"),
    book(5, "openssh", "postlfs/openssh.html", "openssh-10.2p1.tar.gz"),
    book(6, "nodejs", "general/nodejs.html", "node-v22.22.0.tar.xz"),

    # Added after the fact: curl and wget are required or recommended by a large
    # share of BLFS, so having them present saves repeated detours later. Their
    # closure is libunistring -> libidn2 -> libpsl. libpsl is not optional in
    # practice: BLFS notes that building curl without it has "severe security
    # implications" (it is what stops cookies being set across public suffixes).
    book(7, "libunistring", "general/libunistring.html", "libunistring-1.4.1.tar.xz"),
    book(8, "libidn2", "general/libidn2.html", "libidn2-2.3.8.tar.gz"),
    book(9, "libpsl", "basicnet/libpsl.html", "libpsl-0.21.5.tar.gz"),
    book(10, "curl", "basicnet/curl.html", "curl-8.18.0.tar.xz"),
    book(11, "wget", "basicnet/wget.html", "wget-1.25.0.tar.gz"),

    # git: no new dependencies. Its one recommended dep is cURL (for http/https
    # remotes), and OpenSSH covers git-over-ssh -- both already installed above.
    book(12, "git", "general/git.html", "git-2.53.0.tar.xz"),

    # Added post-deployment (2026-08-25 baseline hardware audit): cpio is a build
    # dependency for the hand-crafted microcode initrd (blfs-intel-microcode below),
    # not something Claude Code needs. No new dependencies of its own.
    book(13, "cpio", "general/cpio.html", "cpio-2.15.tar.bz2"),

    # Added 2026-08-25: BLFS's general post-LFS setup, ahead of a first non-root user.
    # No tarball -- this is a configuration page, not a package build. Four blocks
    # (~/.bash_profile, ~/.profile, ~/.bashrc, ~/.bash_logout) get redirected to
    # /etc/skel via overrides, per the book's own suggested modification in skel.html.
    book(14, "shell-startup-files", "postlfs/profile.html", ""),

    # Added 2026-08-25: standing policy from here on is to install BLFS's Recommended
    # dependencies by default, not just Required -- but check each one against what
    # this box actually is before pulling it in (see blfs-vim decision in the build
    # report: vim's only Recommended dep is a GTK3 desktop GUI, skipped as wrong for
    # a headless server, not blindly installed). sudo itself has no Recommended deps.
    book(15, "sudo", "postlfs/sudo.html", "sudo-1.9.17p2.tar.gz"),

    # Requires the netfilter-legacy-enabled kernel (6.18.10-nftables) -- the running
    # kernel this system shipped with has neither NF_TABLES nor
    # NETFILTER_XTABLES_LEGACY, so a plain book build would produce a binary that
    # can't create the `filter` table at all. Kernel side is a separate rebuild
    # (kernel-config.sh), tracked in BUILD-REPORT.md, not this recipe.
    book(16, "iptables", "postlfs/iptables.html", "iptables-1.8.12.tar.xz"),
]
