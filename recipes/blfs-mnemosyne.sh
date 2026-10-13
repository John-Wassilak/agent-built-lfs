#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers Mnemosyne.
# source: github.com/mnemosyne-proj/mnemosyne, tag 2.11 (2023-11-12, the latest release),
# archive/refs/tags/2.11.tar.gz saved as mnemosyne-2.11.tar.gz. sha256
# a042252c2fb8c69c44d048e3f3cfca142189fe7d1bb55e0ad98f8edeeb3ae1cd. GitHub tag archive,
# no upstream signature.
# rationale: operator request (2026-10-12), a spaced-repetition flash card program.
# Runtime closure, from the README and the module-level imports: PyQt6 + PyQt6-WebEngine
# (cards render in a QWebEngineView), matplotlib (statistics), cheroot + WebOb (sync and
# web servers), argon2-cffi (sync password hashing), legacy-cgi (web_server.py imports
# cgi, removed in Python 3.13). gTTS and googletrans back two optional plugins and are not
# installed; cherrypy, decorator, sphinx and pytest appear in pyproject.toml but nothing
# under mnemosyne/ imports them.
# Build backend: poetry-core (blfs-poetry-core). Its build script, poetry-build.py, runs
# `make build`, which generates mnemosyne/pyqt_ui/ui_*.py from the .ui files with the
# bundled pyuic6 wrapper on PyQt6.uic, so PyQt6 must be installed first.
# The 2.11 tag's pyproject.toml still says version 2.10.1.2 (mnemosyne/version.py says
# 2.11), so the wheel and the pip metadata carry 2.10.1.2.
# Install uses --no-deps for the same reason: the declared dependencies include the
# unbuilt packages above, and the real ones are separate steps.
# setup.py's data_files (desktop entry, icon, translations) are not applied by a wheel
# install; the desktop entry and icon are installed by hand below. Translations (po/)
# are not built: en-US only, as for libreoffice.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user --no-deps mnemosyne-proj

install -vDm644 mnemosyne.desktop /usr/share/applications/mnemosyne.desktop
install -vDm644 pixmaps/mnemosyne.png /usr/share/icons/hicolor/128x128/apps/mnemosyne.png
install -vDm644 mnemosyne.1 /usr/share/man/man1/mnemosyne.1
gtk-update-icon-cache -qtf /usr/share/icons/hicolor 2>/dev/null || true
update-desktop-database -q /usr/share/applications 2>/dev/null || true
