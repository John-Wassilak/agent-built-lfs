#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/qt6.html
# title  : Qt-6.10.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: hich use QtMultimedia. Not having a backend available can cause any program that uses
#   ctx: QtMultimedia to crash. For example, Konsole can exit with a SIGABRT if no backend is
#   ctx: provided for QtMultimedia to use. Setting the installation prefix Installing in /opt/qt6
#   ctx: The BLFS editors recommend installing Qt6 in a directory other than /usr, i.e. /opt/qt6.
#   ctx: To do this, set the following environment variable:
export QT6PREFIX=/opt/qt6

# --- block 1 --------------------------------------------------
#   ctx: Tip Sometimes the installation paths are hardcoded into installed files. This is the
#   ctx: reason why /opt/qt6 is used as installation prefix instead of /opt/qt-6.10.2. To create
#   ctx: a versioned Qt6 directory, you may rename the directory and create a symlink:
#   TAGS: admon:tip   [DISABLED - review]
# mkdir -pv /opt/qt-6.10.2
# ln -sfnv qt-6.10.2 /opt/qt6

# --- block 2 --------------------------------------------------
#   ctx: long. The instructions below do not build the tutorials and examples. Removing the
#   ctx: -nomake line will create additional resources.. Note The BLFS editors do not recommend
#   ctx: installing Qt6 into the /usr hierarchy because it becomes difficult to find components
#   ctx: and to update to a new version. Disable a conflicting declaration on i686 systems and
#   ctx: fix a build error due to SIMD intrinsics in QtMultimedia:
if [ "$(uname -m)" == "i686" ]; then
    sed -e "/^#elif defined(Q_CC_GNU_ONLY)/s/.*/& \&\& 0/" \
        -i qtbase/src/corelib/global/qtypes.h                          &&
    export CXXFLAGS+="-DDISABLE_SIMD -DPFFFT_SIMD_DISABLE"
fi

# --- block 3 --------------------------------------------------
#   ctx: Install Qt6 by running the following commands:
./configure -prefix $QT6PREFIX      \
            -sysconfdir /etc/xdg    \
            -dbus-linked            \
            -openssl-linked         \
            -system-sqlite          \
            -skip qt3d                 \
            -skip qt5compat            \
            -skip qtactiveqt           \
            -skip qtcharts             \
            -skip qtcoap               \
            -skip qtconnectivity       \
            -skip qtdatavis3d          \
            -skip qtdoc                \
            -skip qtgraphs             \
            -skip qtgrpc               \
            -skip qthttpserver         \
            -skip qtimageformats       \
            -skip qtlanguageserver     \
            -skip qtlocation           \
            -skip qtlottie             \
            -skip qtmqtt               \
            -skip qtnetworkauth        \
            -skip qtopcua              \
            -skip qtpositioning        \
            -skip qtquick3d            \
            -skip qtquick3dphysics     \
            -skip qtquickeffectmaker   \
            -skip qtquicktimeline      \
            -skip qtremoteobjects      \
            -skip qtscxml              \
            -skip qtsensors            \
            -skip qtserialbus          \
            -skip qtserialport         \
            -skip qtspeech             \
            -skip qttools              \
            -skip qttranslations       \
            -skip qtvirtualkeyboard    \
            -skip qtwebchannel         \
            -skip qtwebengine          \
            -skip qtwebsockets         \
            -skip qtwebview            \
            -nomake examples        \
            -no-rpath               \
            -no-sbom                \
            -journald               &&
ninja

# --- block 4 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
ninja install

# --- block 5 --------------------------------------------------
#   ctx: Remove references to the build directory from installed library dependency (prl) files
#   ctx: by running the following command as the root user:
find $QT6PREFIX/ -name \*.prl \
   -exec sed -i -e '/^QMAKE_PRL_BUILD_DIR/d' {} \;

# --- block 6 --------------------------------------------------
#   ctx: Install images and create the menu entries for installed applications. Again as the root
#   ctx: user:
#   REVIEWED [drop]: Installs icons/desktop entries for assistant/designer/linguist/qdbusviewer, all from qttools -- not in the trimmed -submodules list above (block 3), so qttools/src doesn't exist and this block would fail outright (`pushd: qttools/src: No such file or directory`). None of those GUI dev tools are wanted here; this project only needs Qt6 as a Quickshell/DankMaterialShell runtime dependency.
# pushd qttools/src &&
# 
# install -v -Dm644 assistant/assistant/images/assistant-128.png       \
#                   /usr/share/pixmaps/assistant-qt6.png               &&
# 
# install -v -Dm644 designer/src/designer/images/designer.png          \
#                   /usr/share/pixmaps/designer-qt6.png                &&
# 
# install -v -Dm644 linguist/linguist/images/icons/linguist-128-32.png \
#                   /usr/share/pixmaps/linguist-qt6.png                &&
# 
# install -v -Dm644 qdbus/qdbusviewer/images/qdbusviewer-128.png       \
#                   /usr/share/pixmaps/qdbusviewer-qt6.png             &&
# popd &&
# 
# 
# cat > /usr/share/applications/assistant-qt6.desktop << EOF
# [Desktop Entry]
# Name=Qt6 Assistant
# Comment=Shows Qt6 documentation and examples
# Exec=$QT6PREFIX/bin/assistant
# Icon=assistant-qt6.png
# Terminal=false
# Encoding=UTF-8
# Type=Application
# Categories=Qt;Development;Documentation;
# EOF
# 
# cat > /usr/share/applications/designer-qt6.desktop << EOF
# [Desktop Entry]
# Name=Qt6 Designer
# GenericName=Interface Designer
# Comment=Design GUIs for Qt6 applications
# Exec=$QT6PREFIX/bin/designer
# Icon=designer-qt6.png
# MimeType=application/x-designer;
# Terminal=false
# Encoding=UTF-8
# Type=Application
# Categories=Qt;Development;
# EOF
# 
# cat > /usr/share/applications/linguist-qt6.desktop << EOF
# [Desktop Entry]
# Name=Qt6 Linguist
# Comment=Add translations to Qt6 applications
# Exec=$QT6PREFIX/bin/linguist
# Icon=linguist-qt6.png
# MimeType=text/vnd.trolltech.linguist;application/x-linguist;
# Terminal=false
# Encoding=UTF-8
# Type=Application
# Categories=Qt;Development;
# EOF
# 
# cat > /usr/share/applications/qdbusviewer-qt6.desktop << EOF
# [Desktop Entry]
# Name=Qt6 QDbusViewer
# GenericName=D-Bus Debugger
# Comment=Debug D-Bus applications
# Exec=$QT6PREFIX/bin/qdbusviewer
# Icon=qdbusviewer-qt6.png
# Terminal=false
# Encoding=UTF-8
# Type=Application
# Categories=Qt;Development;Debugger;
# EOF

# --- block 7 --------------------------------------------------
#   ctx: dule. On 32-bit systems, this will cause the build process to fail with an inlining
#   ctx: error in Qt6's bundled copy of the PhysX SDK. -libproxy: This switch enables the usage
#   ctx: of libproxy for determining proxy server information. Configuring Qt6 Configuration
#   ctx: Information If Sudo-1.9.17p2 is installed, QT6DIR should be available to the super user
#   ctx: as well. Execute the following commands as the root user:
cat > /etc/sudoers.d/qt << "EOF"
Defaults env_keep += QT6DIR
EOF

# --- block 8 --------------------------------------------------
#   ctx: You now need to update the following configuration files so that Qt6 is correctly found
#   ctx: by other packages and system processes. As the root user, update the /etc/ld.so.conf
#   ctx: file and the dynamic linker's run-time cache file:
cat >> /etc/ld.so.conf << EOF
# Begin Qt addition

/opt/qt6/lib

# End Qt addition
EOF

ldconfig

# --- block 9 --------------------------------------------------
#   ctx: As the root user, create the /etc/profile.d/qt6.sh file:
cat > /etc/profile.d/qt6.sh << "EOF"
# Begin /etc/profile.d/qt6.sh

QT6DIR=/opt/qt6

pathappend $QT6DIR/bin           PATH
pathappend $QT6DIR/lib/pkgconfig PKG_CONFIG_PATH

export QT6DIR

# End /etc/profile.d/qt6.sh
EOF

