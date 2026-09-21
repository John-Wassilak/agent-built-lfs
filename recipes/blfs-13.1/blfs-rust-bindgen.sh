#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/rust-bindgen.html
# title  : rust-bindgen-0.72.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ired: 219 MB Estimated build time: 0.4 SBU (with parallelism=8) rust-bindgen
#   ctx: Dependencies Required rustc-1.97.1 and LLVM-22.1.8 (with Clang, runtime) Note An
#   ctx: Internet connection is needed for building this package. The system certificate store
#   ctx: may need to be set up with make-ca-1.16.1 before building this package. Installation of
#   ctx: rust-bindgen Install rust-bindgen by running the following commands:
_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

cargo build --release

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: cargo test --release. Four tests,
#   ctx: header_issue_544_stylo_creduce_2_hpp, header_constified_enum_module_overflow_hpp,
#   ctx: header_typedef_pointer_overlap_h, and header_nsbasehashtable_hpp, are known to fail.
#   ctx: Now, as the root user:
install -v -m755 target/release/bindgen /usr/bin

# --- block 2 --------------------------------------------------
#   ctx: Still as the root user, install the Bash and Zsh completion support files:
bindgen --generate-shell-completions bash \
    > /usr/share/bash-completion/completions/bindgen
bindgen --generate-shell-completions zsh  \
    > /usr/share/zsh/site-functions/_bindgen

