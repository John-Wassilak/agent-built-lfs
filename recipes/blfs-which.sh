#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/which.html
# title  : Which-2.23 and Alternatives
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: package. Note This package is known to build and work properly using an LFS 13.0
#   ctx: platform. Package Information Download (HTTP):
#   ctx: https://ftpmirror.gnu.org/which/which-2.23.tar.gz Download MD5 sum:
#   ctx: 1963b85914132d78373f02a84cdb3c86 Download size: 197 KB Estimated disk space required:
#   ctx: 1.2 MB Estimated build time: less than 0.1 SBU Installation of Which Install which by
#   ctx: running the following commands:
./configure --prefix=/usr &&
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install

# --- block 2 --------------------------------------------------
#   ctx: Contents Installed Program: which Installed Libraries: None Installed Directories: None
#   ctx: Short Descriptions which shows the full path of (shell) commands installed in your PATH
#   ctx: The 'which' Script The second option (for those who don't want to install the package)
#   ctx: is to create a simple script (execute as the root user):
#   REVIEWED [drop]: The page is 'Which-2.23 and Alternatives'. This block is the alternative: 'The second option (for those who don't want to install the package) is to create a simple script'. We install the real package in blocks 0-1, so running this would overwrite the just-installed /usr/bin/which binary with a shell script.
# cat > /usr/bin/which << "EOF"
# #!/bin/bash
# type -pa "$@" | head -n 1 ; exit ${PIPESTATUS[0]}
# EOF
# chmod -v 755 /usr/bin/which
# chown -v root:root /usr/bin/which

