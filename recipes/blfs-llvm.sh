#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/llvm.html
# title  : LLVM-21.1.8 (with clang)
# rationale: Required by Firefox (tier 15) -- "used for bindgen even if using
# gcc", can't use Rust's bundled copy the way this project did earlier for
# just the Rust toolchain itself (tier 6 decision, scoped narrowly to Rust).
# compiler-rt not downloaded -- optional, not needed by anything in this
# plan. Test suite not run -- needs Linux-PAM (not part of this system, same
# reason tests are skipped project-wide) to get clean core-dump-free runs,
# and 19 extra SBU for no verification value here. Largest single build in
# this whole project (13 SBU estimated by the book); expect this to take a
# while.
set -e

tar -xf ../llvm-cmake-21.1.8.src.tar.xz
tar -xf ../llvm-third-party-21.1.8.src.tar.xz
sed '/LLVM_COMMON_CMAKE_UTILS/s@../cmake@cmake-21.1.8.src@' -i CMakeLists.txt
sed '/LLVM_THIRD_PARTY_DIR/s@../third-party@third-party-21.1.8.src@' -i cmake/modules/HandleLLVMOptions.cmake

tar -xf ../clang-21.1.8.src.tar.xz -C tools
mv tools/clang-21.1.8.src tools/clang

grep -rl '#!.*python' | xargs sed -i '1s/python$/python3/'

sed 's/utility/tool/' -i utils/FileCheck/CMakeLists.txt

mkdir -v build
cd build

CC=gcc CXX=g++ \
cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_SKIP_INSTALL_RPATH=ON \
      -D LLVM_ENABLE_FFI=ON \
      -D CMAKE_BUILD_TYPE=Release \
      -D LLVM_BUILD_LLVM_DYLIB=ON \
      -D LLVM_LINK_LLVM_DYLIB=ON \
      -D LLVM_ENABLE_RTTI=ON \
      -D LLVM_TARGETS_TO_BUILD="host;AMDGPU" \
      -D LLVM_BINUTILS_INCDIR=/usr/include \
      -D LLVM_INCLUDE_BENCHMARKS=OFF \
      -D CLANG_DEFAULT_PIE_ON_LINUX=ON \
      -D CLANG_CONFIG_FILE_SYSTEM_DIR=/etc/clang \
      -W no-dev -G Ninja ..
ninja

ninja install

echo "### version"
clang --version 2>&1 || true
llvm-config --version 2>&1 || true
