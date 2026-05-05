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
