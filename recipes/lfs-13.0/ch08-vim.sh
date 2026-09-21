#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/vim.html
# title  : 8.75. Vim-9.2.0078
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: s a powerful text editor. Approximate build time: 3.2 SBU Required disk space: 217 MB
#   ctx: Alternatives to Vim If you prefer another editor—such as Emacs, Joe, or Nano—please
#   ctx: refer to https://www.linuxfromscratch.org/blfs/view/13.0-systemd/postlfs/editors.html
#   ctx: for suggested installation instructions. 8.75.1. Installation of Vim First, change the
#   ctx: default location of the vimrc configuration file to /etc:
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h

# --- block 1 --------------------------------------------------
#   ctx: Prepare Vim for compilation:
./configure --prefix=/usr

# --- block 2 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 3 --------------------------------------------------
#   ctx: To prepare the tests, ensure that user tester can write to the source tree and exclude
#   ctx: one file containing tests requiring curl or wget:
chown -R tester .
sed '/test_plugin_glvs/d' -i src/testdir/Make_all.mak

# --- block 4 --------------------------------------------------
#   ctx: Now run the tests as user tester:
#   REVIEWED [drop]: vim's test suite. Not one of the critical three (glibc/gcc/binutils), so out of scope per the tests policy. It also failed here, and its output is redirected to vim-test.log so the failure never reaches the build log. Block starts with `su tester`, which is why the test-command regex missed it.
# su tester -c "TERM=xterm-256color LANG=en_US.UTF-8 make -j1 test" \
#    &> vim-test.log

# --- block 5 --------------------------------------------------
#   ctx: terminal (especially while we are overriding the TERM variable to satisfy some
#   ctx: assumptions of the test suite). The problem can be avoided by redirecting the output to
#   ctx: a log file as shown above. A successful test will result in the words ALL DONE in the
#   ctx: log file at completion. Two tests, Test_client_server_stopinsert() and
#   ctx: Test_popup_setbuf(), are known to fail on some systems. Install the package:
make install

# --- block 6 --------------------------------------------------
#   ctx: Many users reflexively type vi instead of vim. To allow execution of vim when users
#   ctx: habitually enter vi, create a symlink for both the binary and the man page in the
#   ctx: provided languages:
ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done

# --- block 7 --------------------------------------------------
#   ctx: By default, Vim's documentation is installed in /usr/share/vim. The following symlink
#   ctx: allows the documentation to be accessed via /usr/share/doc/vim-9.2.0078, making it
#   ctx: consistent with the location of documentation for other packages:
ln -sv ../vim/vim92/doc /usr/share/doc/vim-9.2.0078

# --- block 8 --------------------------------------------------
#   ctx: in the past. The “nocompatible” setting is included below to highlight the fact that a
#   ctx: new behavior is being used. It also reminds those who would change to “compatible” mode
#   ctx: that it should be the first setting in the configuration file. This is necessary because
#   ctx: it changes other settings, and overrides must come after this setting. Create a default
#   ctx: vim configuration file by running the following:
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF

# --- block 9 --------------------------------------------------
#   ctx: t with the mouse when working in chroot or over a remote connection. Finally, the if
#   ctx: statement with the set background=dark setting corrects vim's guess about the background
#   ctx: color of some terminal emulators. This gives the highlighting a better color scheme for
#   ctx: use on the black background of these programs. Documentation for other available options
#   ctx: can be obtained by running the following command:
#   REVIEWED [drop]: `vim -c ':options'` opens vim interactively so a human can browse settings. Purely exploratory; would block the driver.
# vim -c ':options'

