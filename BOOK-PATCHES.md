# Candidate upstream book reports

Findings from this project that are defects in the *book*, not in this build. Everything
here was hit by a real build on `server` or `laptop`, recorded at the time in an override
`reason` and a `BUILD-REPORT.md` section; this file is the subset that is worth sending
upstream, ranked, with the book text re-read to confirm each claim still describes what
the page actually says.

Scope: all against **BLFS 13.0-systemd** (`book/blfs-13.0`, "Version 13.0"), except the
one LFS item in tier 3. Verified against the local book copy on 2026-09-08.

**Before filing anything, re-check the finding against the current development book.**
Only item 1 has been: it is still present in r13.1-84. The rest were found against 13.0
and may already be fixed. Confirm BLFS's current submission channel (ticket tracker vs.
blfs-dev list) before writing anything up as a patch.

---

## Tier 1 -- the book ships something that cannot work

### 1. The Google Location Service key is dead, and the book spends it on two pages

Two pages write the same key:

- `xsoft/firefox.html` -- the mozconfig carries
  `ac_add_options --with-google-location-service-api-keyfile=$PWD/google-key`, and the
  page's own command writes `AIzaSyDxKL42zsPjbke5O8_rPVpVrLrJ8aeE9rQ` into that file.
- `basicnet/geoclue2.html` -- the Configuring section creates
  `/etc/geoclue/conf.d/90-lfs-google.conf` pointing `[wifi]` at the same key.

The key returns 403 for anyone:

    $ curl -s -X POST -d '{}' -H 'Content-Type: application/json' \
        'https://www.googleapis.com/geolocation/v1/geolocate?key=AIza...9rQ'
    403  "PERMISSION_DENIED: You must enable Billing on the Google Cloud Project"

Re-verified 2026-09-08. Reader-visible symptom: every geolocation request fails with
`POSITION_UNAVAILABLE` / `GeolocationPositionError` code 2, which reads as a missing
dependency rather than a dead credential, so the natural next move is to build GeoClue --
which spends the same key again.

A second, separable defect on the same GeoClue page. The prose says:

> In March of 2024, Mozilla announced the shutdown of the Mozilla Location Service. [...]
> The only supported alternative by upstream is to use Google's Geolocation Service.

Upstream says otherwise, in the file GeoClue itself installs. Stock
`/etc/geoclue/geoclue.conf` documents three providers, with the compiled-in default named
explicitly:

    # If unset, defaults to an URL defined at build-time,
    # this URL is 'https://api.beacondb.net/v1/geolocate'
    ...
    # To use the Positon geolocation service, uncomment this URL.
    #url=https://api.positon.xyz/v1/geolocate?key=56aba903-...

So the book's config file *overrides a working keyless default with a dead endpoint*.
beaconDB is the Ichnaea-compatible successor to MLS; Positon ships an upstream key for
non-commercial distributors (their terms, quoted in that same config file).

**Proposed change.** On the GeoClue page, delete the `90-lfs-google.conf` block entirely
and replace the "only supported alternative" paragraph with a pointer to the provider list
in `/etc/geoclue/geoclue.conf`. Doing nothing is strictly better than what the page does
now. On the Firefox page, drop the key or mark it non-functional; worth noting alongside
it that the book's mozconfig keeps `--disable-necko-wifi`, so Firefox on its own is
IP-accuracy only even with a working key.

**Strength:** highest. One curl reproduces it, it affects every reader of two pages, and
the fix is deletion.

**Evidence in this repo:** `recipes/blfs-overrides.json` (`blfs-geoclue2` block 2),
`PRACTICES.md` "The book's Google Location Service key is dead", and
`hosts/laptop/BUILD-REPORT.md` 2026-09-08 sections.

### 2. gdk-pixbuf built without glycin can load no images at all

`x/gdk-pixbuf.html` detects glycin at configure time --
`$(pkgconf glycin-2 || echo -D glycin=disabled)` -- but hardcodes the built-in loaders
off regardless:

    -D png=disabled -D gif=disabled -D jpeg=disabled -D tiff=disabled

The Command Explanation is deliberate: the disables exist "to make the configuration of
the first build (without glycin) consistent". glycin is *Recommended*, and circular (build
gdk-pixbuf, then glycin, then rebuild gdk-pixbuf).

So a reader who follows the page and does not complete the circular rebuild -- or who
skips a Recommended dependency, as the book's own conventions permit -- gets a gdk-pixbuf
with both loader paths off. Measured here: `loaders.cache` listing zero loaders, GTK's own
bundled PNG icons failing with "Unrecognized image file format", and an abort in
`Gtk:ERROR ensure_surface_for_gicon`. Nothing warns; the package builds and installs
cleanly.

**Proposed change.** Gate the four `*=disabled` switches on glycin the same way the
glycin switch itself is gated, or promote glycin to Required.

**Evidence:** `recipes/blfs-overrides.json` (`blfs-gdk-pixbuf` block 0).

## Tier 2 -- the printed command hard-fails without a Recommended dependency, and the page documents no escape

One shape, ten pages. The meson/cmake option is a plain boolean, or a feature passed
straight into `required:`, so a missing optional dependency is a **configure error, not a
degraded build**. BLFS documents the escape switch on some pages (`-D tests=false` on
libnotify, `-D wallpaper=disabled` on xdg-desktop-portal-gtk, the three ModemManager
switches on GeoClue) and not on others. These are the ones where it is missing:

| Page | Missing escape | Absent dependency, as the page classifies it |
|---|---|---|
| `basicnet/geoclue2.html` | `-D vapi=false` | Vala -- Recommended |
| `gnome/libsecret.html` | `-D vapi=false` | Vala -- Recommended (`manpage` *is* documented) |
| `gnome/gcr4.html` | `-D vapi=false` | Vala -- Optional |
| `gnome/gcr.html` (3.41.2) | `-D introspection=false` | no `vapi` option exists in this release; `gck/meson.build` gates VAPI generation on `introspection` |
| `gnome/gnome-keyring.html` | `-D pam=false`, `-D manpage=false` | Linux-PAM, libxslt -- both Recommended; page has no Command Explanations at all |
| `postlfs/polkit.html` | `-D authfw=shadow`, `-D introspection=false` | Linux-PAM -- Recommended; the page recommends PAM but offers no build-without path (`man` *is* covered by a note) |
| `basicnet/networkmanager.html` | `-D nmtui=false`, `-D introspection=false` | newt -- Recommended "(for nmtui)"; the package's own error names the fix |
| `x/libnotify.html` | `-D introspection=disabled` | GObject Introspection -- "Optional (Required if building GNOME)" |
| `general/poppler.html` | `-DENABLE_LIBOPENJPEG=none` | OpenJPEG -- Recommended; the page documents the equivalent `ENABLE_QT5/QT6=OFF` switches |
| `postlfs/emacs.html` | `--with-xpm=ifavailable` | libXpm -- listed nowhere on the page; configure names the fix itself |

Two sub-cases worth calling out separately, because they are more than a missing sentence:

- **`polkit`'s `authfw` default is `pam`** whatever the prose says about PAM being
  Recommended. `-D authfw=shadow` is a supported value in `meson_options.txt` and is the
  documented-nowhere path for a PAM-less system.
- **`libnotify`'s `tests=true` default makes GTK-4 a hard dependency** --
  `dependency('gtk4', ..., required: get_option('tests'))` -- so the page's printed
  command fails on any system without a GNOME stack. The page documents `-D tests=false`,
  but as an optional extra rather than as the requirement it is.

**Proposed change.** One "Use this switch if you have not installed X" entry per row,
matching the wording BLFS already uses elsewhere. Submittable as one report about the
inconsistency, or one per page.

**Evidence:** the corresponding entries in `recipes/blfs-overrides.json`; every one cites
the exact configure error it was found by.

---

## Tier 3 -- presentation and documentation nits

- **`postlfs/openssh.html`, `make install-sshd`.** The Systemd Unit section says to install
  the unit "included in the blfs-systemd-units-20251204 package" and then shows
  `make install-sshd` as a bare command block, immediately after openssh's own install
  commands. It is a target of that other package's Makefile. A reader working linearly runs
  it in the openssh tree, where it fails. Naming the directory would fix it.
- **`postlfs/emacs.html`, no `--with-pgtk`.** Emacs's own native-Wayland GTK backend is not
  mentioned on the page at any level. Without it Emacs runs under XWayland regardless of
  what else on the system is Wayland-capable (confirmed here via `hyprctl clients` showing
  `xwayland: true`). A feature gap rather than a bug, but the flag has existed far longer
  than this book edition.
- **`x/gtk3.html`, backends left on meson `auto`.** Whichever backend happens to be
  installed at build time is baked into `gdk-3.0.pc`'s `Requires:`. Removing that package
  later breaks `pkg-config gtk+-3.0` for every consumer, including Firefox's configure,
  even if nothing ever used the backend. A caution note, or explicit `x11_backend=`/
  `wayland_backend=` in the printed command, would prevent it.
- **LFS `ch08-stripping`** (the only LFS-book item here). The strip loop's `-name '*.so*'`
  matches GNU ld linker scripts (`libc.so`, `libm.so`, `libgcc_s.so`) and, by glob
  accident, systemd `.socket` unit files. None are ELF, so strip prints "file format not
  recognized" for each. Harmless in the interactive shell the book assumes; a tighter
  pattern or `|| true` would make the step clean. Lowest priority of anything here.

---

## Checked and dropped -- not book defects

Recorded so nobody re-derives them:

- **`x/libei.html` test suite.** The re-enable command is guarded prose ("If you have both
  munit and structlog installed"). Our extractor's problem, not the book's.
- **`xsoft/xdg-utils.html` and xmlto.** xmlto is listed *Required*. The build failure came
  from deliberately skipping a Required dependency.
- **Firefox and ALSA.** The page already ships the commented
  `--enable-audio-backends=alsa` line with the right instruction above it.
- **`x/xdg-desktop-portal-gtk.html` and `-D wallpaper=disabled`.** Documented in Command
  Explanations, exactly as it should be.

---

## Suggested order of submission

1. Item 1 alone, as its own report. Single issue, one-line reproduction, affects every
   reader of two pages, fix is a deletion. Do not bundle it with anything.
2. Item 2, separately -- it needs a judgement call from the editors (gate the switches, or
   promote glycin to Required) rather than a text change.
3. Tier 2 as one report framed around the inconsistency, with the table. Splitting it per
   page is the safer choice if the tracker prefers single-page tickets.
4. Tier 3 only if the earlier ones land well.

Re-check every item against the development book first; only item 1 has been.

---

## Working notes -- how to pick this up cold

Written 2026-09-09, at the end of the session that produced this file. Everything below is
method and state, not findings, so that a later session does not have to re-derive it.

### The book is readable locally

`book/blfs-13.0/` is present in the working tree (untracked -- see `README.md`, "Getting
the books"). The LFS book is **not**: `bin/extract-recipes.py --check` reports "no LFS book
at book/13.0", which is why the one LFS item in tier 3 was taken from an override reason
rather than re-read from source. Get the LFS book before working that item.

Page paths used above, for reference:

    basicnet/geoclue2.html      xsoft/firefox.html      x/gdk-pixbuf.html
    x/libnotify.html            general/poppler.html    x/libei.html
    xsoft/xdg-utils.html        postlfs/openssh.html    postlfs/emacs.html
    gnome/libsecret.html        gnome/gcr.html          gnome/gcr4.html
    gnome/gnome-keyring.html    postlfs/polkit.html     basicnet/networkmanager.html

The pages are DocBook-generated HTML with heavy markup. Reading them as text:

    python3 - "$@" <<'PY'
    import sys, re, html
    for f in sys.argv[1:]:
        t = open(f, encoding='utf-8', errors='replace').read()
        t = re.sub(r'<script.*?</script>|<style.*?</style>', '', t, flags=re.S)
        print(re.sub(r'\n{3,}', '\n\n', html.unescape(re.sub(r'<[^>]+>', '', t))))
    PY

then `sed -n '/Dependencies/,/Contents/p'` gets the dependency list, the printed command
and the Command Explanations in one block -- which is exactly the three things every
finding above turns on. Note the distinction the whole of tier 2 rests on: BLFS classes a
dependency Required / Recommended / Optional, and separately may or may not document the
switch that lets you build without it. The finding is always the *second* thing missing.

### Re-verifying item 1

    curl -s -o /dev/null -w '%{http_code}\n' -X POST -H 'Content-Type: application/json' \
      -d '{}' 'https://www.googleapis.com/geolocation/v1/geolocate?key=AIzaSyDxKL42zsPjbke5O8_rPVpVrLrJ8aeE9rQ'

`403` is the finding; the body carries the billing message. An empty `{}` body is
deliberate -- it sends no scan data and no coordinates, and the billing check fails before
any lookup happens. The provider list that contradicts the page's prose is in
`/etc/geoclue/geoclue.conf` on `laptop` (installed by the package, not by us), around the
`[wifi]` section.

### Where each finding's evidence lives

Every tier 1 and tier 2 row traces to an override `reason` naming the exact configure
error it was found by:

- shared, book-wide: `recipes/blfs-overrides.json`
- machine-specific: `hosts/laptop/blfs-overrides.json`, `hosts/server/blfs-overrides.json`
- the geolocation narrative, with measurements: `hosts/laptop/BUILD-REPORT.md`,
  2026-09-08 sections
- the machine-independent half of the same: `PRACTICES.md`, "The book's Google Location
  Service key is dead, and BLFS spends it twice"

To re-derive the candidate list from scratch, dump every `reason` across the four override
files and grep for real-failure language (`Real failure`, `ERROR`, `fails outright`,
`hard-error`). That produced ~36 hits, of which the ones above survived reading in full;
the rest were project choices (skipping a dependency on purpose) rather than book defects.

### What is not done

- **Nothing has been submitted, and the submission channel was never confirmed.** BLFS
  takes bug reports through a ticket tracker and a development mailing list; which one
  suits a documentation fix, and whether they want a patch against the XML source rather
  than prose, is unresearched. Settle that before writing any of this up.
- **Only item 1 was re-checked against the development book** (r13.1-84, key still
  present, both pages). Items 2 through tier 3 are 13.0-only. Any of them may already be
  fixed upstream; check before filing, or the report is noise.
- **No XML patch exists for anything.** The book source is the DocBook XML, not the
  rendered HTML read here, so a patch means fetching the book's own repository.
- The tier 2 table names the switch but not, in most cases, the exact wording BLFS uses
  for the equivalent explanation elsewhere. Lifting the phrasing from a page that does
  document its escape (libnotify's `-D tests=false` entry is the cleanest example) will
  make the reports look native.
