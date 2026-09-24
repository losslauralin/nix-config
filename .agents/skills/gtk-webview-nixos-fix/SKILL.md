---
name: gtk-webview-nixos-fix
description: Fix GTK/WebKitGTK apps packaged from prebuilt binaries in this nix-config when they render wrong on NixOS — a UI that comes out too small with a clipped header and mostly blank window, a window that opens white, a renderer that dies mid-paint and freezes, or text that scales inconsistently between launching terminals. Use when packaging a Tauri/WebKitGTK/GTK app under pkgs/by-name, when such an app looks broken while its backend is demonstrably healthy, or when a GTK app's window and its content disagree about scale.
---

# GTK/WebView on NixOS

Purpose: recognise the environment gaps that make a GTK/WebKitGTK app look
broken on NixOS while the app itself is fine, and fix them in the package
wrapper rather than the app.

The failures below share a shape. The app launches, its backend works, and the
UI is still unusable — so it reads as an upstream bug when it is a missing
piece of the runtime environment. The package derivation is the right place to
supply it: NixOS puts *system profile* packages on the shared search paths, and
a store package is not one.

Two independent gaps take this shape. Check them in order; each has a
distinctive symptom.

## Gap 1: the app cannot read desktop settings

**Symptom.** The whole UI renders small — every dimension shrinks together, as
if the design were zoomed out — the top of the window is clipped, and the rest
of the window is mostly blank. It looks the same at any window size. Launching
from a different terminal can change it.

**Why.** GTK 3 and WebKitGTK read font, DPI and scaling from GSettings, and the
schemas live in `gtk3` (`org.gtk.Settings.*`) and `gsettings-desktop-schemas`
(`org.gnome.desktop.interface`). NixOS puts only system profile packages'
compiled schemas on `XDG_DATA_DIRS`. A store package that runs GTK without
adding its own schema directories gets no schemas at all, and falls back to
compiled-in defaults — silently.

The measurement that confirms it: compare a size the app's own CSS declares
against what renders. In aghub the sidebar is `w-60` (240px) but measured
~160px, which puts the CSS root font size at ~10.6px instead of 16px — every
rem-based dimension shrinks by a third. That ratio is the tell, and it is not a
window-size problem.

**Fix.** Put both schema directories on `XDG_DATA_DIRS` in the wrapper, using
`--prefix` so the session's own entries stay reachable (schema lookup merges
every directory, so order does not decide who wins):

```nix
postFixup = ''
  # The two directories are addressed as <pkg>/share/gsettings-schemas/<name>,
  # the layout glib's setup hook installs. Assert them instead of trusting the
  # path: a stale layout would leave the wrapper pointing at nothing and this
  # fix would silently do nothing.
  test -d ${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}/glib-2.0/schemas
  test -d ${gtk3}/share/gsettings-schemas/${gtk3.name}/glib-2.0/schemas

  wrapProgram $out/bin/<app> \
    --prefix XDG_DATA_DIRS : ${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}:${gtk3}/share/gsettings-schemas/${gtk3.name}
'';
```

`gsettings-desktop-schemas` is a wrapper-only input: nothing links against it,
only its compiled schemas are used. Say so in the `buildInputs` comment so the
next reader does not delete it as unused.

**Related gap in the same wrapper.** WebKitGTK sends network requests through
GIO, and NixOS does not provide `glib-networking` by default, so the TLS
backend degrades to `GDummyTlsBackend` and every HTTPS request fails silently —
the app opens with normal text and layout, but remote images and icons never
render. Add its modules with `--suffix` (not `--set`, which would displace the
session's `GIO_EXTRA_MODULES` holding dconf's modules):

```nix
--suffix GIO_EXTRA_MODULES : ${glib-networking}/lib/gio/modules
```

`pkgs/by-name/aghub/package.nix` carries the full worked example of both.

## Gap 2: scale is forced instead of delegated

**Symptom.** A large window with a small island of content in one corner, or
the content in the wrong place entirely. Unlike Gap 1 the UI does not shrink
proportionally; the window and its contents disagree.

**Why.** `GDK_SCALE` and `GDK_DPI_SCALE` can enlarge the native window without
enlarging CSS content, which leaves a big blank window with the UI pinned in
one corner. The compositor session already knows the display scale, and every
NixOS desktop here sets it there (Umbriel passes `scale = display.scaling`).

**Fix.** Set neither variable. Let the session decide.

`GDK_BACKEND` is the other forced-choice trap, but it fails the other way: a
Wayland session where GTK picks X11/XWayland. Ask GDK which backend it chose
rather than inferring it from the process — a `libX11` mapping is not proof of
XWayland, since GTK links the X11 backend regardless of which one it uses:

```bash
GDK_DEBUG=misc <app> 2>&1 | grep 'Trying .* backend'
# Gdk-Message: ...: Trying wayland backend
```

That line comes from GDK itself, so it settles the question. Only pin the
backend when it reports X11 on a Wayland session.

## Gap 3: GPU paths the driver cannot complete

**Symptom.** The window opens white or blank, or the renderer dies mid-paint
and the window freezes on a partial frame. A dialog that uses blur or another
accelerated effect is a reliable reproducer.

**Why.** WebKitGTK's DMA-BUF renderer asks the NVIDIA proprietary driver for a
buffer format it does not provide, or a WebKit GPU worker thread asserts during
teardown. Both are driver-side defects, not packaging gaps — which is why this
one is **not** fixed in the package.

**Fix.** This belongs to the host, because "this machine has NVIDIA" is a
machine fact: the same package installs on hosts without it, and a package-level
variable would degrade their rendering for nothing. The working mitigations,
their ordering, and the measured evidence live in
`modules/hosts/mechrevo-nixos-noctalia/default.nix`. Read that comment before
adding a variable here; one of the two that used to sit there turned out to be
redundant, and the surviving one is `__NV_DISABLE_EXPLICIT_SYNC=1`.

Reach for the cheapest mitigation that holds. Each further step trades away
GPU painting — `WEBKIT_DISABLE_DMABUF_RENDERER=1` drops a faster rendering
path, a CPU-rendering setting drops GPU painting for every WebKitGTK app on
the host — so the order recorded there is the state that was measured to work,
and a variable beyond it needs its own evidence.

## Verify a fix

Rebuild and run the app, then confirm at the layer that actually changed:

- **Schema gap.** The wrapper's `XDG_DATA_DIRS` is the evidence, not the app's
  appearance alone: `grep XDG_DATA_DIRS $(readlink -f $(which <app>))` and check
  both schema paths are present and exist. Compare a CSS-declared size against
  the rendered one to confirm the ratio is back to 1:1.
- **Forced scale.** Confirm the session's scale reaches the app and that
  neither variable is set anywhere in the tree:
  `rg 'GDK_SCALE|GDK_DPI_SCALE' --glob '!/nix/store/**'`.
- **Backend.** Run the app with `GDK_DEBUG=misc` and read the line GDK prints,
as shown above.

Report the exact command and its output. A packaging fix that is not verified
at the wrapper layer can be a no-op that looks like success.

## Stop Rules

- If the app is available in nixpkgs, use that instead of packaging a prebuilt
  binary; this skill assumes no Nix expression exists upstream.
- If you are about to set `GDK_SCALE`, `GDK_DPI_SCALE`, or `GDK_BACKEND`, stop
  and verify the failure first — all three are guesses that trade one wrong
  rendering for another.
- If the failure only appears on one host, the fix belongs in that host's spec,
  not in the package wrapper.
- If a package fact would come from `/nix/store/**`, stop and ask. Use
  `nh search packages`, upstream release files, or the user instead.
