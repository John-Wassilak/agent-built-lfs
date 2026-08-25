# glibc-2.43 test suite (Chapter 8, critical)

Run: attempt 1, 44.4 min wall clock, `make check` exit status 2.
Log: logs/ch08-glibc.log (preserved).

## Results
FAIL  3   XPASS 4   ERROR 0   UNSUPPORTED 589

| Test | Assessment |
|---|---|
| io/tst-lchmod | Explicitly documented by the book: "known to fail in the LFS chroot environment." |
| io/tst-faccessat-setuid | Tests setuid access checks; we build as root in chroot, where every access succeeds. Expected. |
| malloc/tst-malloc-too-large-malloc-hugetlb2 | Depends on host kernel hugepage configuration. Book notes host-kernel-dependent failures. |

XPASS entries (elf/tst-ifunc-isa-1, -1-static, -2, -2-static) are unexpected *passes* and benign.

## Verdict
Accepted. Book: "A few failures out of over 6000 tests can generally be ignored."
3 failures, all attributable to the chroot/root/host-kernel environment rather than to
the build. No ERRORs.
