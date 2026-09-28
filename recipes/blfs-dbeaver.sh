#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers DBeaver.
# rationale: Operator-requested (2026-09-28). DBeaver Community Edition, the upstream
# prebuilt Linux x86_64 tarball from github.com/dbeaver/dbeaver/releases/tag/26.2.1
# (the file dbeaver.io/files/dbeaver-ce-latest-linux.gtk.x86_64.tar.gz redirected to
# on that date). sha256 16d7bd01e84f8cd8f46d6976ac127fa25678ec010953c9b4dce41933af2067e8
# matches the digest GitHub publishes for the release asset; it is checked again below.
#
# Binary, not from source: DBeaver is an Eclipse RCP application built with Maven/Tycho,
# and a source build needs a JDK plus a network-fetched Maven dependency tree. laptop
# has no JDK by design (see the LibreOffice --without-java note in its packages.py:
# BLFS's OpenJDK lists CUPS as a required build dependency). The tarball carries its own
# jlink'd runtime (dbeaver/jre, Java 25.0.3), which dbeaver.ini's launcher uses without
# any system Java, so nothing Java-related lands outside /opt/dbeaver.
#
# `ldd` against every ELF file in the tarball, and against the SWT native libraries
# unpacked from plugins/org.eclipse.swt.gtk.linux.x86_64_*.jar, found every dependency
# already satisfied (GTK3, cairo, atk, libX11/Xwayland). The one "not found",
# libswt-awt's libjawt.so, lives in the bundled jre/lib and resolves at runtime.
# WebKitGTK is not installed; SWT dlopens it only for its Browser widget (DBeaver's
# embedded help/tips pages), which then fails to open while the rest of the workbench
# runs. A trial launch under Hyprland (GTK3 on Wayland) reached "Finish initialization"
# with no errors in the workspace log.
#
# Installed under /opt/dbeaver as one self-contained tree, the same convention as the
# other large third-party trees here (/opt/rustc, /opt/go). The shipped .desktop file
# points at /usr/share/dbeaver-ce; it is rewritten to /opt/dbeaver. DBeaver's built-in
# updater cannot write to a root-owned /opt tree -- upgrade by bumping this recipe.
set -e

TARBALL=/sources/dbeaver-ce-26.2.1-linux-x86_64.tar.gz
echo "16d7bd01e84f8cd8f46d6976ac127fa25678ec010953c9b4dce41933af2067e8  $TARBALL" \
    | sha256sum -c -

# lfsbuild has already unpacked the tarball and cd'd into its top-level dbeaver/.
rm -rf /opt/dbeaver
install -d /opt/dbeaver
cp -a . /opt/dbeaver/
chown -R root:root /opt/dbeaver

ln -sfn /opt/dbeaver/dbeaver /usr/bin/dbeaver

install -Dm644 dbeaver.png /usr/share/pixmaps/dbeaver.png
sed -e 's|^Path=.*|Path=/opt/dbeaver/|' \
    -e 's|^Exec=.*|Exec=env NO_AT_BRIDGE=1 /opt/dbeaver/dbeaver %U|' \
    -e 's|^Icon=.*|Icon=dbeaver|' \
    -e 's|^Name=.*|Name=DBeaver|' \
    dbeaver-ce.desktop > /usr/share/applications/dbeaver-ce.desktop
chmod 644 /usr/share/applications/dbeaver-ce.desktop

echo "### runtime deps resolvable"
if ldd /opt/dbeaver/dbeaver /opt/dbeaver/jre/bin/java | grep "not found"; then
    echo "MISSING deps above"; exit 1
fi
echo "ok   all resolved"

echo "### bundled runtime"
/opt/dbeaver/jre/bin/java -version 2>&1
