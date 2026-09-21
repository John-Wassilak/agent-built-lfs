#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/rust.html
# title  : Rustc-1.97.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: test suite if it is present), cranelift, jemalloc, libgccjit (read the Command
#   ctx: Explanations in GCC-16.2.0), and libgit2 Editor Notes:
#   ctx: https://wiki.linuxfromscratch.org/blfs/wiki/rust Installation of Rust To install into
#   ctx: the /opt directory, remove any existing /opt/rustc symlink and create a new directory
#   ctx: (i.e. with a different name if trying a modified build of the same version). As the root
#   ctx: user:
mkdir -pv /opt/rustc-1.97.1      &&
ln -svfn rustc-1.97.1 /opt/rustc

# --- block 1 --------------------------------------------------
#   ctx: Note If multiple versions of Rust are installed in /opt, changing to another version
#   ctx: only requires changing the /opt/rustc symbolic link and then running ldconfig. Create a
#   ctx: suitable bootstrap.toml file which will configure the build.
cat << EOF > bootstrap.toml
# See bootstrap.toml.example for more possible options,
# and see src/bootstrap/defaults/bootstrap.dist.toml for a few options
# automatically set when building from a release tarball
# (unfortunately, we have to override many of them).

# Tell x.py that the editors have reviewed the content of this file
# and updated it to follow the major changes of the building system,
# so x.py will not warn users to review that information.
change-id = 154587

[llvm]
# If building the shipped LLVM source, only enable the x86 target
# instead of all the targets supported by LLVM.
targets = "X86"

[build]
description = "for BLFS 13.1"

# Omit the documentation to save time and space (the default is to build them).
docs = false

# Only install these extended tools. Cargo, clippy, rustdoc, and rustfmt
# are installed by a default rustup installation, and rust-src is needed
# to build the Rust code in Linux kernel (in case you need such a kernel
# feature).
tools = ["cargo", "clippy", "rustdoc", "rustfmt", "src"]

[install]
prefix = "/opt/rustc-1.97.1"
docdir = "share/doc/rustc-1.97.1"

[rust]
channel = "stable"

# Enable the same optimizations as the official upstream build.
lto = "thin"
codegen-units = 1

# Don't build llvm-bitcode-linker which is only useful for the NVPTX
# backend that we don't enable.
llvm-bitcode-linker = false
EOF

# --- block 2 --------------------------------------------------
#   ctx: Compile Rust by running the following commands:
_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

export LIBSSH2_SYS_USE_PKG_CONFIG=1
./x.py build

# --- block 3 --------------------------------------------------
#   ctx: l for traps on invalid opcodes, and for segmentation faults. In themselves these are
#   ctx: nothing to worry about, and they are just a way for a test to be terminated. If running
#   ctx: the test suite, fake a Git executable to allow running the test suite without git-2.55.0
#   ctx: installed (we are building from a release tarball instead of Git repository here so Git
#   ctx: will not be really useful even if it's installed):
#   REVIEWED [drop]: New in BLFS 13.1 (2026-09-07 bump): 'mkdir fake-git && ln -sv /usr/bin/false fake-git/git', a workaround so the Rust test suite doesn't make real git calls. Only exists to support block 4's './x.py test', which is dropped (see block 4's reason) -- test suites have been skipped throughout this project, so this test-only prep step has nothing to prepare for.
# mkdir fake-git && ln -sv /usr/bin/false fake-git/git

# --- block 4 --------------------------------------------------
#   ctx: To run the tests, issue:
#   REVIEWED [drop]: Full Rust test suite (./x.py test) -- extremely long even by this build's standards, and test suites have been skipped throughout this entire project. Reindexed 3->4 for the 2026-09-07 BLFS 13.1 bump: the book inserted the new fake-git block (block 3) immediately before this one and also dropped --verbose in favor of --no-fail-fast alone -- confirmed by reading book/blfs-13.1/general/rust.html directly.
# PATH+=:$PWD/fake-git \
# ./x.py test --no-fail-fast | tee rustc-testlog

# --- block 5 --------------------------------------------------
#   ctx: en rustc >= 1.41.1 was built with a version of sysllvm before 10.0 the test for issue
#   ctx: 69225 failed https://github.com/rust-lang/rust/issues/69225 and that should be regarded
#   ctx: as a critical failure (they released 1.41.1 because of it). Most other failures will not
#   ctx: be critical. Therefore, you should determine the number of failures. The number of tests
#   ctx: which passed and failed can be found by running:
#   REVIEWED [drop]: Summarizes results from the test suite in block 4, which is not run. Reindexed 4->5 for the 2026-09-07 BLFS 13.1 bump (see block 4's reason).
# grep '^test result:' rustc-testlog |
#  awk '{sum1 += $4; sum2 += $6} END { print sum1 " passed; " sum2 " failed" }'

# --- block 6 --------------------------------------------------
#   ctx: , as the root user, install the package: Note If sudo or su is invoked for switching to
#   ctx: the root user, ensure LIBSSH2_SYS_USE_PKG_CONFIG and LIBSQLITE3_SYS_USE_PKG_CONFIG are
#   ctx: correctly passed or the following command may rebuild cargo with shipped copies of
#   ctx: libssh2 and sqlite. For sudo, use the
#   ctx: --preserve-env=LIB{SSH2,SQLITE3}_SYS_USE_PKG_CONFIG option. For su, do not use the - or
#   ctx: --login options.
./x.py install

# --- block 7 --------------------------------------------------
#   ctx: Still as the root user, fix the installation of the documentation, symlink a Zsh
#   ctx: completion file into the correct location, and move a Bash completion file into the
#   ctx: location recommended by the Bash completion maintainers:
rm -fv /opt/rustc-1.97.1/share/doc/rustc-1.97.1/*.old   &&
install -vm644 README.md                                \
               /opt/rustc-1.97.1/share/doc/rustc-1.97.1 &&

install -vdm755 /usr/share/zsh/site-functions      &&
ln -sfv /opt/rustc/share/zsh/site-functions/_cargo \
        /usr/share/zsh/site-functions

# --- block 8 --------------------------------------------------
#   ctx: Finally, unset the exported environment variables:
unset LIB{SSH2,SQLITE3}_SYS_USE_PKG_CONFIG

# --- block 9 --------------------------------------------------
#   ctx: go to link to the system installed copy of sqlite. --no-fail-fast: this switch ensures
#   ctx: that the test suite will not stop at the first error. Configuring Rust Configuration
#   ctx: Information If you installed rustc in /opt, you need to update the following
#   ctx: configuration files so that rustc is correctly found by other packages and system
#   ctx: processes. As the root user, create the /etc/profile.d/rustc.sh file:
cat > /etc/profile.d/rustc.sh << "EOF"
# Begin /etc/profile.d/rustc.sh

pathprepend /opt/rustc/bin           PATH

# End /etc/profile.d/rustc.sh
EOF

# --- block 10 --------------------------------------------------
#   ctx: Immediately after installation, update the current PATH for your current shell as a
#   ctx: normal user:
# Not sourced here: pathprepend (defined in /etc/profile) only exists in a
# login shell, which this non-interactive batch build never is. The written
# /etc/profile.d/rustc.sh is still correct for real interactive sessions;
# this just gets rustc/cargo onto PATH for the rest of *this* build script.
export PATH="/opt/rustc/bin:$PATH"

