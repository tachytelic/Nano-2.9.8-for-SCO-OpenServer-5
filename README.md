# GNU nano 2.9.8 for SCO OpenServer 5

A working build of [GNU nano 2.9.8](https://www.nano-editor.org/) (June
2018, last 2.9 release) for **SCO OpenServer 5.0.7**.

```
$ nano -V
GNU nano, version 2.9.8

$ nano /etc/hosts        # full-screen modeless editor with syntax highlighting
```

## Why 2.9.8 specifically?

Nano 4.x and 5.x require **ncurses** with wide-character support (the
`mvwchgat`, `wresize`, `wcwidth` family of functions). SCO ships
traditional 8-bit curses without those. We could build modern ncurses
first, but that's a multi-day project on its own; nano 2.9.8 is the
last release that builds clean against SCO's stock `libcurses` after
a single `--disable-utf8` configure flag, and it has all the ergonomics
that matter:

- Syntax highlighting (40+ languages bundled in `share/nano/`)
- Search & replace with regex
- Multi-buffer editing (`-F`)
- Auto-indent, smart home, mouse support
- Backup files, undo / redo
- Soft-wrap and hard-wrap

What you don't get vs newer nano:

- UTF-8 / multi-byte input (build is 8-bit only)
- The `--zap` / `--linenumbers` features added in 4.x
- Some refinements to the help screen and keybind defaults

For typical SCO sysadmin work — editing config files, scripts, plain
text — these are non-issues.

## Install

> **Fresh SCO box?** Install [curl with TLS](https://github.com/tachytelic/curl-7.88.1-for-SCO-OpenServer-5)
> first — that's the only file that needs to be transferred via `scp`.
> After that, every release on tachytelic/* (including this one) fetches
> over HTTPS from GitHub.

The release tarball is ~230 KB. Fetch and extract on the SCO box:

```sh
# On the SCO box (assumes curl-with-TLS is on PATH — see curl-sco):
curl -LO https://github.com/tachytelic/Nano-2.9.8-for-SCO-OpenServer-5/releases/download/v1.0.0/nano-2.9.8-sco.tar.gz
gtar xzf nano-2.9.8-sco.tar.gz
# or with stock tools: gunzip -c nano-2.9.8-sco.tar.gz | /usr/bin/tar xf -
mv install /usr/local/nano-2.9.8
ln -s /usr/local/nano-2.9.8/bin/nano /usr/local/bin/nano
nano -V
```

The binary dynamically links against `/usr/lib/libcurses.so.1`,
`/usr/lib/libsocket.so.2`, `/usr/lib/libnsl.so`, `/usr/lib/libc.so.1` —
all stock SCO 5.0.7 libraries. **No external runtime dependencies.**

### Syntax highlighting

The release tarball includes 40+ syntax-highlighting files at
`/usr/local/nano-2.9.8/share/nano/`. To enable them globally, drop a
`/etc/nanorc` (or `~/.nanorc`) with:

```
include "/usr/local/nano-2.9.8/share/nano/*.nanorc"
```

Now `nano foo.c` highlights C, `nano foo.py` highlights Python, etc.

### 256-color terminal support

SCO 5.0.7's stock `xterm` terminfo entry has zero color capabilities at
all (no `setaf`/`setab`, no `colors` count) — predates the 8/16/256
colour conventions completely. The bundled `extras/xterm-256color-sco.src`
is a 256-colour `xterm-256color` entry, derived from modern ncurses and
adjusted to fit SCO's 16-bit terminfo number storage (the only required
change was capping `pairs` from 65536 → 32767).

Install once on the SCO box:

```sh
tic extras/xterm-256color-sco.src
```

Then in any login session connecting to SCO from a 256-colour-capable
terminal emulator (PuTTY, modern xterm, iTerm2, gnome-terminal, …):

```sh
export TERM=xterm-256color
```

**PuTTY users — there are two extra toggles to flip on the client side.**
Modern Linux/macOS terminals auto-detect 256-colour and need no setup,
but PuTTY's defaults are conservative. In your saved session settings:

- *Window → Colours* — tick **"Allow terminal to specify ANSI colours"**
  and **"Allow terminal to use xterm 256-colour mode"**.
- *Connection → Data* — set **"Terminal-type string"** to `xterm-256color`
  (so SCO sees the right `$TERM` at login automatically; otherwise you
  have to `export` it every time).
- *(Optional — Window → Translation)* — set "Remote character set" to
  `UTF-8` if you also use other apps. Won't help nano in this build
  (`--disable-utf8`), but other shells/programs benefit.

Save the session, then reconnect (PuTTY only sends the terminal-type
string at session start, so a live session keeps its old setting until
you reopen it).

Verify:

```sh
$ tput colors
256
$ tput setaf 196 | od -c | head -1
0000000  033   [   3   8   ;   5   ;   1   9   6   m
```

Then nano picks colours from its syntax files automatically — `c.nanorc`,
`python.nanorc`, etc.

**One SCO-specific limit worth knowing**: `libcurses` caps simultaneous
foreground/background colour *pairs* at **64**, regardless of what
terminfo says. That's plenty for nano (typical themes use 10–20 pairs)
but a tight ceiling if you push vim hard. Probed empirically:

```c
start_color();
COLORS;       // → 256  ✅
COLOR_PAIRS;  // → 64   ⚠ (libcurses internal cap, not a terminfo issue)
init_pair(50, 196, 0);   // → 0  (success — 256-colour FG/BG values work)
init_pair(100, 200, 16); // → -1 (fails: pair index >= 64)
```

## Building from source

You probably don't need to do this — the release tarball is what
`build.sh` produces. If you want to rebuild:

This is a **native build** on SCO. Same pattern as the python/curl/lua
builds in this repo's siblings.

### Requirements

- **GCC 3.4 or later** somewhere on PATH (or `CC=`/`GCC=` env var).
  The SCO-shipped GCC 2.95.3 may also work; we built with 3.4.6.
- `/usr/gnu/bin/{gmake,gtar}`, `/usr/bin/patch`
- **bash** as the configure shell. SCO's `/bin/sh` is `/bin/ksh`,
  dramatically slower than bash on autoconf scripts.

### Build

```sh
cd nano-sco
./build.sh
```

The script downloads `nano-2.9.8.tar.gz` from nano-editor.org, configures
with `--disable-nls --disable-utf8`, builds with
`LIBS="-lcurses -lsocket -lnsl"` (the latter two for `gethostname`,
which `files.c` calls when constructing lock-file names), installs to
`./install/`, strips. ~3 minutes on typical SCO hardware. **No source
patches needed** — nano 2.9.8 builds clean on SCO with just the right
configure/link flags.

## Repository layout

```
build.sh                     Native-build script (run on SCO)
extras/
  xterm-256color-sco.src     terminfo source: 256-colour xterm,
                             adjusted for SCO's 16-bit terminfo
                             number storage. `tic` it once on SCO
                             and `export TERM=xterm-256color`.
LICENSE                      MIT (covers build script only)
README.md                    This file
```

No `patches/` directory — none needed. The prebuilt 230 KB tarball ships
via the **[Releases](../../releases)** page, not via clone bloat.

## License

GNU nano is © Free Software Foundation, distributed under
[GPLv3+](https://www.gnu.org/licenses/gpl-3.0.html). The prebuilt binary
is unmodified upstream nano 2.9.8.

The build script in this repo is released under the MIT license — see
[LICENSE](LICENSE).

## See also

- [curl-7.88.1 for SCO](https://github.com/tachytelic/curl-7.88.1-for-SCO-OpenServer-5)
  — the natural first install on a fresh SCO box.
- [GNU bash 3.2.57 for SCO](https://github.com/tachytelic/Bash-3.2.57-for-SCO-OpenServer-5),
  [GNU tar 1.34 for SCO](https://github.com/tachytelic/Tar-1.34-for-SCO-OpenServer-5)
  — sibling builds.
- [More SCO OpenServer 5 binaries](https://tachytelic.net/2017/07/sco-openserver-5-binaries/)
  — the hub.
