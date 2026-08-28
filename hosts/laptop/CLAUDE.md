# `laptop`

Not built. Scaffold only: `host.toml` with every hardware field marked TODO,
`packages.py` at `BASE` alone, and a `kernel-config.sh` that deliberately exits 1 until
its four TODOs are worked through.

`BOOTSTRAP.md` is the procedure. Read it before anything else here.

The one rule that matters at this stage: **audit the hardware before writing config.**
Every TODO in `host.toml` is an input to the kernel config or the package selection, and
guessing any of them costs a rebuild. `server`'s build report has a worked example of the
audit (its "Baseline hardware audit" section) and of what happens when a hardware fact is
assumed instead of checked.

Do not copy `server`'s GPU, audio, media or boot config. It is a 2011 desktop with a
Kepler card on a legacy proprietary driver, and almost none of that transfers. The
portable parts -- the X11 libraries, fonts, awesome, rofi, dunst, picom, alacritty -- are
already in the shared `recipes/` tree and can be lifted as-is.
