#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: x/xorg7.html: every Xorg/XCB-family BLFS recipe from here on (util-macros, xorgproto, libXau, libXdmcp, xcb-proto, libxcb, libxcvt, xcb-util, and later xorg-xwayland) uses $XORG_PREFIX and $XORG_CONFIG in its literal build commands -- the book has the reader export them once, persist them via /etc/profile.d, and reuse throughout. No page-specific command block captures this since it is shared setup, not part of any one package's page.
set -e

cat > /etc/profile.d/xorg.sh << EOF
XORG_PREFIX="/usr"
XORG_CONFIG="--prefix=\$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var --disable-static"
export XORG_PREFIX XORG_CONFIG
EOF
chmod 644 /etc/profile.d/xorg.sh
echo "### written:"
cat /etc/profile.d/xorg.sh

