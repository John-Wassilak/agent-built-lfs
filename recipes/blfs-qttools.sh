#!/bin/bash
# HAND-AUTHORED recipe -- BLFS has no page for an individual Qt module; see the longer
# note in recipes/blfs-qt5compat.sh, which this step is a sibling of.
#
# source: download.qt.io/archive/qt/6.10/6.10.2/submodules/qttools-everywhere-src-
# 6.10.2.tar.xz
#
# provenance: md5 027685b4765edbf911781b1dc86f8e9d, matching md5sums.txt in that same
# submodules/ directory. sha256 of what was downloaded is
# 1e3d2c07c1fd76d2425c6eaeeaa62ffaff5f79210c4e1a5bc2a6a9db668d5b24. Same-origin check,
# no upstream signature. Pinned to 6.10.2 to match qtbase.
#
# rationale: this step exists because a decision was overtaken by a fact found live, and
# the sequence is worth recording rather than tidying away.
#
# When the nextcloud-desktop work was planned (2026-09-12), qttools looked purely
# optional: the client guards its translations with `if(Qt6LinguistTools_FOUND)`, so
# skipping it cost the .qm files and nothing else, and the operator chose English-only
# over a fourth standalone Qt module. That was correct about nextcloud and wrong about
# the chain. KArchive (seq 329) then failed at configure time:
#
#   CMake Error at /usr/share/ECM/modules/ECMPoQmTools.cmake:155 (find_package):
#     Failed to find required Qt component "LinguistTools".
#   Call Stack: ECMPoQmTools.cmake:249 -> CMakeLists.txt:129
#                                          (ecm_install_po_files_as_qm)
#
# KArchive calls ecm_install_po_files_as_qm(poqm) unconditionally, and ECM's own
# function only returns early when the po directory is absent -- which it is not; the
# 6.23.0 tarball ships poqm/ with 70-odd languages. There is no cmake option to turn it
# off. So for KArchive, and therefore for the client, Qt6LinguistTools is REQUIRED, not
# recommended.
#
# The alternative considered and rejected was a sed deleting that one line from
# KArchive's CMakeLists before configuring. It would have preserved the operator's
# original choice, but at the cost of hand-editing upstream source to drop a feature --
# the kind of undocumented deviation this repo's override mechanism exists to make
# unnecessary. Building the real dependency is the honest fix.
#
# Side effect, stated because it reverses the earlier decision rather than working
# around it: with lrelease present, nextcloud-desktop (seq 333) now finds
# Qt6LinguistTools and builds its ~60 translated .qm files too. The UI will be
# localised, not English-only.
#
# Portable, shared per CLAUDE.md's shared/host test.
set -e

# See blfs-qt5compat.sh for why qt-cmake rather than plain cmake.
#
# The QT_FEATURE_* flags below are not tidiness. A first attempt at this recipe passed
# none of them, on the assumption that qttools' GUI programs would self-disable for want
# of optional dependencies the way qdoc does. That was wrong and the build log said so
# within two minutes: it was compiling Qt Widgets Designer, and a vendored copy of
# litehtml (src/assistant/qlitehtml/src/3rdparty/litehtml, gumbo parser and all) for
# Assistant's help viewer. Both of their CONDITIONs in this tarball's own
# configure.cmake are satisfied here -- Designer needs Qt::Widgets, Qt::Network and png,
# Assistant needs only a shared-library build -- and all of that is present. The build
# was stopped before it installed anything and restarted with this list.
#
# What is wanted from this module is lrelease, lupdate and lconvert, plus the
# Qt6LinguistTools cmake package that KArchive and nextcloud-desktop look for. Nothing
# on this host is a Qt development workstation: there is no use here for a WYSIWYG form
# designer, an offline Qt documentation browser, a pixel magnifier or a font-cache
# pregenerator.
#
#   QT_FEATURE_linguist stays ON, and deliberately so -- src/linguist/CMakeLists.txt
#   opens with `if(NOT QT_FEATURE_linguist) return()`, which would skip lrelease,
#   lupdate, lconvert AND the fake Linguist module that provides Qt6LinguistTools. It
#   gates the tools, not just the GUI. The Qt Linguist GUI comes with them (it has its
#   own inner condition on Widgets and Quick, both present) and there is no flag that
#   separates the two without patching.
#   QT_FEATURE_qdoc is already off for want of libclang, which is not built here; it is
#   listed anyway so a host that later builds clang does not silently acquire a
#   documentation generator from this step.
"$QT6DIR/bin/qt-cmake" -G Ninja -S . -B build \
      -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_INSTALL_PREFIX="$QT6DIR" \
      -D QT_BUILD_TESTS=OFF \
      -D QT_BUILD_EXAMPLES=OFF \
      -D QT_FEATURE_assistant=OFF \
      -D QT_FEATURE_fullqthelp=OFF \
      -D QT_FEATURE_designer=OFF \
      -D QT_FEATURE_qdoc=OFF \
      -D QT_FEATURE_distancefieldgenerator=OFF \
      -D QT_FEATURE_pixeltool=OFF \
      -D QT_FEATURE_qtattributionsscanner=OFF \
      -D QT_FEATURE_qtdiag=OFF \
      -D QT_FEATURE_qtplugininfo=OFF

# ninja ignores MAKEFLAGS; take the job count from it explicitly. See blfs-qt5compat.sh.
JOBS=$(printf '%s' "${MAKEFLAGS:-}" | grep -oE '\-j ?[0-9]+' | grep -oE '[0-9]+' | head -1 || true)
: "${JOBS:=1}"
echo "### building with --parallel $JOBS (MAKEFLAGS=${MAKEFLAGS:-unset})"
cmake --build build --parallel "$JOBS"

cmake --install build

echo "### version"
"$QT6DIR/bin/lrelease" -version
echo "### cmake package the dependents actually look for"
ls -d "$QT6DIR/lib/cmake/Qt6LinguistTools"
