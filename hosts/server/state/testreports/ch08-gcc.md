# gcc-15.2.0 test suite (Chapter 8, critical)

Run: 226.0 min (3.8h). `su tester -c "make -k check"` exit status **0**.

Test .exp files executed: 548

## Summary (from ../contrib/test_summary)
  		=== gcc Summary ===
  # of expected passes		97577
  # of unexpected failures	6
  # of expected failures		668
  # of unsupported tests		1920
  		=== g++ tests ===
  		=== gcc Summary ===
  # of expected passes		113860
  # of unexpected failures	5
  # of expected failures		808
  # of unsupported tests		1874
  		=== g++ Summary ===
  # of expected passes		5868
  # of expected failures		48
  # of unsupported tests		53
  		=== g++ Summary ===
  # of expected passes		242649
  # of expected failures		2234
  # of unsupported tests		1996
  		=== libstdc++ Summary ===
  # of expected passes		3705
  # of unexpected failures	1
  # of expected failures		32
  # of unsupported tests		49
  		=== libstdc++ Summary ===
  # of expected passes		3650
  # of expected failures		23
  # of unsupported tests		130
  		=== libgomp tests ===
  		=== libstdc++ Summary ===
  # of expected passes		8026
  # of unexpected failures	3
  # of expected failures		31
  # of unsupported tests		92
  		=== libitm Summary ===
  # of expected passes		44
  # of expected failures		3
  # of unsupported tests		1
  		=== libatomic Summary ===
  # of expected passes		54

## Verdict
Accepted. Totals across all suites: roughly **475,000 expected passes against 15
unexpected failures** (gcc 11, libstdc++ 4, g++ 0). Note the exit status of 0 comes from
`make -k`, which continues past failures -- so the summary above, not the exit code, is
the real signal. 15 unexpected failures out of ~475k tests is a healthy toolchain and
well within what the book treats as normal.
Ran as the unprivileged 'tester' user created in ch07-createfiles, per the book.
1751 files installed (manifest recorded).
