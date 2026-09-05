#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for Quickshell.
# rationale: Not in the BLFS 13.0 book, not reachable in AUR from this host (Anubis
# anti-bot blocks a plain fetch) -- sourced directly from upstream's own tagged
# release (git.outfoxxed.me/quickshell/quickshell, mirrored at
# github.com/quickshell-mirror/quickshell, tag v0.3.1), cross-checked against the
# real quickshell-git AUR PKGBUILD (fetched via aur.archlinux.org's cgit raw
# endpoint, which Anubis does not gate) for the depends/makedepends list, and
# against DankMaterialShell's own real `import Quickshell.*` lines (its actual QML
# source, not documentation) for which optional CMake features this project needs:
# Bluetooth, Mpris, Notifications, Pipewire, Polkit, SystemTray, UPower, Wayland
# (+ layer-shell, for panels/bars), Sockets (IPC, what the `dms` Go binary talks
# to). Explicitly OFF below:
#   - SERVICE_PAM: DMS's lock-screen widget needs it, but this host deliberately
#     never built Linux-PAM (see packages.py's own note near seq 15 -- the book's
#     own PAM page warns Shadow/systemd need reinstalling/reconfiguring afterward
#     for it to take effect, a much bigger risk than this project wants for one
#     optional widget on a system whose login/su/sudo already work). Operator
#     decision 2026-09-04: keep that call, build without lock-screen support.
#   - USE_JEMALLOC, CRASH_HANDLER: both optional (better allocator / better crash
#     backtraces), neither required for functionality, both would add jemalloc/
#     cpptrace as brand-new dependencies for a benefit nothing here needs yet.
# X11 was first built OFF (this project's laptop target is Wayland/Hyprland only, no
# X11-backed shell panels wanted even though XWayland itself is separately built), then
# turned back ON same day once live verification (`dms run`) failed:
# `module "Quickshell.I3" is not installed`, traced to DankMaterialShell's own
# `Services/BarWidgetService.qml` (`import Quickshell.I3` alongside
# `import Quickshell.Hyprland`). Quickshell's `Quickshell.I3` QML module (the i3/sway
# IPC protocol client -- a plain Unix-socket JSON client, not an actual X11 display
# connection) lives under `src/x11/i3/`, gated on the `X11` CMake option purely for
# source-tree organization, not because it needs a display -- confirmed by reading
# `src/x11/CMakeLists.txt` and `src/x11/i3/CMakeLists.txt` directly upstream. Its only
# real dependency is XCB (`find_package(XCB REQUIRED COMPONENTS XCB)`), already built
# here for XWayland. `I3`/`I3_IPC` are both ON by CMake's own default once `X11` is ON,
# no extra flags needed. This was NOT a case of needing a newer/untagged Quickshell --
# v0.3.1 already has the module, it just needed this one flag flipped.
# Everything else (WAYLAND, WAYLAND_WLR_LAYERSHELL, BLUETOOTH, the SERVICE_* set,
# SOCKETS) is left on CMake's own auto-detection -- all their real deps (wayland,
# wayland-protocols, dbus/glib2, polkit, libpipewire, mesa/libdrm) are already
# built on this host, so they are expected to auto-enable; the configure-summary
# output is the actual check, not an assumption.
set -e

mkdir build
cd build
cmake -GNinja -B . -S .. \
      -D CMAKE_BUILD_TYPE=RelWithDebInfo \
      -D CMAKE_INSTALL_PREFIX=/usr \
      -D INSTALL_QML_PREFIX=lib/qt6/qml \
      -D DISTRIBUTOR="agent-built-lfs (laptop)" \
      -D USE_JEMALLOC=OFF \
      -D CRASH_HANDLER=OFF \
      -D SERVICE_PAM=OFF \
      -D X11=ON
cmake --build .
cmake --install .

echo "### version"
qs --version
