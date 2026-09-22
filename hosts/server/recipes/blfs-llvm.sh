#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/llvm.html
# title  : LLVM-22.1.8 (with clang)
#
# HOST COPY, created 2026-09-21. The shared recipes/blfs-llvm.sh is the 13.0 recipe and
# has to stay that way: `laptop` is pinned to BLFS 13.0 and declares this package
# hand(79.1, "llvm", "llvm-21.1.8.src.tar.xz", "... shared recipe"), so it reads that
# file. 13.1 does not just bump the version, it changes the source layout completely,
# and there is no way to write one recipe that is correct for both.
#
# rationale: Required by Firefox ("used for bindgen even if using gcc") and, on this
# host, by Mesa -- libgallium, libEGL_mesa, libGLX_mesa and gbm/dri_gbm.so all link
# libLLVM directly. Largest single build in this project; the book estimates 13 SBU for
# 13.0 and this is bigger. Test suite not run, per this project's BLFS test policy: the
# book's own invocation needs a user dbus and systemd-run to get core-dump-free results
# and costs ~19 extra SBU for no verification value here.
#
# Why this rebuild happened at all (2026-09-21). It was not on the version-catch-up list
# `lfsmaint drift` produced, because 13.1 renamed the tarball from llvm-21.1.8.src.tar.xz
# to llvm-project-22.1.8.src.tar.xz and drift matches on package name parsed from the
# filename -- "llvm-project" and "llvm" are different names, so installed 21.1.8 was
# never compared against anything. It surfaced only when blfs-spirv-llvm-translator
# 22.1.5 failed its cmake: 'Could not find a configuration file for package "LLVM" that
# is compatible with requested version "22.1.0"' against the installed 21.1.8. Same
# class of blind spot as the firefox/spidermonkey mis-attribution in the same session.
#
# What changed from the 13.0 recipe, all of it from the book:
#   - ONE tarball. 13.0 shipped llvm + llvm-cmake + llvm-third-party + clang separately
#     and this recipe untarred three of them by hand, patched CMakeLists.txt and
#     HandleLLVMOptions.cmake with seds to point at the unpacked directory names, and
#     moved clang into tools/. All of that is gone: llvm-project-22.1.8.src.tar.xz is
#     the monorepo and clang comes in via -D LLVM_ENABLE_PROJECTS=clang.
#   - compiler-rt IS built now, via -D LLVM_ENABLE_RUNTIMES=compiler-rt. The 13.0
#     rationale said "compiler-rt not downloaded -- optional, not needed by anything in
#     this plan", which was true when it was a separate tarball nobody fetched. It is
#     in the monorepo and the book's own cmake line enables it, so it is built.
#   - Paths are prefixed. The build directory is llvm/build, not build, and the FileCheck
#     sed targets llvm/utils/FileCheck/CMakeLists.txt.
#   - -W no-author replaces -W no-dev.
#   - The python shebang grep is anchored: '#!.*python$' where 13.0 had '#!.*python'.
#     The unanchored form also matched files whose shebang was already python3 (and
#     anything with "python" mid-line), so this is a real correction, not a cosmetic one.
#   - /etc/clang and its two config files are CREATED. This is the one genuinely new
#     block, and it fixes a live defect rather than a version difference: the 13.0
#     recipe passed -D CLANG_CONFIG_FILE_SYSTEM_DIR=/etc/clang and never created that
#     directory. Confirmed on this machine before the rebuild -- /etc/clang did not
#     exist, so clang had been running with no system config file at all and without the
#     -fstack-protector-strong default the option was there to provide.
set -e

# --- block 0: the book's required upstream fix -----------------
patch -Np1 -i ../llvm-22.1.8-upstream_fix-1.patch

# --- block 1: python3 shebangs ---------------------------------
grep -rl '#!.*python$' | xargs sed -i '1s/python$/python3/'

# --- block 2 ---------------------------------------------------
sed 's/utility/tool/' -i llvm/utils/FileCheck/CMakeLists.txt

# --- block 3: system clang config (see header) -----------------
mkdir -pv /etc/clang
for i in clang clang++; do
  echo -fstack-protector-strong > /etc/clang/$i.cfg
done

# --- block 4: configure and build ------------------------------
mkdir -v llvm/build
cd       llvm/build

CC=gcc CXX=g++ \
cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_SKIP_INSTALL_RPATH=ON \
      -D LLVM_ENABLE_FFI=ON \
      -D CMAKE_BUILD_TYPE=Release \
      -D LLVM_BUILD_LLVM_DYLIB=ON \
      -D LLVM_LINK_LLVM_DYLIB=ON \
      -D LLVM_ENABLE_RTTI=ON \
      -D LLVM_TARGETS_TO_BUILD="host;AMDGPU" \
      -D LLVM_ENABLE_PROJECTS=clang \
      -D LLVM_ENABLE_RUNTIMES=compiler-rt \
      -D LLVM_BINUTILS_INCDIR=/usr/include \
      -D LLVM_INCLUDE_BENCHMARKS=OFF \
      -D CLANG_DEFAULT_PIE_ON_LINUX=ON \
      -D CLANG_CONFIG_FILE_SYSTEM_DIR=/etc/clang \
      -W no-author -G Ninja ..
ninja

# Test suite deliberately skipped -- see the header.
# systemctl --user start dbus &&
# systemd-run --user --pty -d -G -p LimitCORE=0 ninja check-all

ninja install

echo "### version"
clang --version 2>&1 || true
llvm-config --version 2>&1 || true
