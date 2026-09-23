#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this module, but as one section of the
# multi-package page general/python-modules.html (#pypa-build), which a book() step
# cannot address. Commands are the book's own (BLFS 13.0). Named pypa-build, the
# book's own anchor, rather than "build", which reads as a verb everywhere else.
# rationale: nmap's only Required dependency -- its Makefile runs `python3 -m build`
# for the ndiff and zenmap wheels. Needs pyproject_hooks (blfs-pyproject-hooks) and
# packaging (LFS). Build backend: flit_core, already installed.
# md5 dc81be0bed3eaef5a6865784182a7487, matching the book.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user build
