{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  nix-update-script,
  # Runtime dependencies of the WebKitGTK / Tauri host shell.
  # Verified against `readelf -d usr/bin/aghub` in the upstream .deb.
  openssl,
  gtk3,
  webkitgtk_4_1,
  libsoup_3,
  glib,
  dbus,
  cairo,
  gdk-pixbuf,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "aghub";
  version = "1.9.1";

  # Upstream publishes no Nix support at all: the Linux desktop app is only
  # shipped as a .deb / .rpm / AppImage. The .deb is the clean input -- it
  # unpacks with plain tools and links system libraries, so autoPatchelfHook
  # can rewrite the interpreter and rpath. The AppImage would ship the same
  # unbundled WebKitGTK dependencies inside a squashfs that still needs the
  # host to provide libwebkit2gtk-4.1.so.0 at standard FHS paths.
  src = fetchurl {
    url = "https://github.com/AkaraChen/aghub/releases/download/v${finalAttrs.version}/aghub_${finalAttrs.version}_amd64.deb";
    hash = "sha256-OHvWXUWVYXed5jUSMdOmis43fNF/DhsHjmolb3dWIXE=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    openssl
    gtk3
    webkitgtk_4_1
    libsoup_3
    glib
    dbus
    cairo
    gdk-pixbuf
  ];

  # Nothing to compile; unpackPhase below produces `usr/` by hand.
  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;
  dontStrip = true;

  unpackPhase = ''
    runHook preUnpack

    dpkg-deb --fsys-tarfile $src | tar --extract --file=- usr
    chmod -R u+w usr

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp usr/bin/aghub usr/bin/ccusage $out/bin/

    # The .deb ships a bare-bones desktop entry; keep upstream's but make it
    # point at the wrapped binary so it launches from the desktop menu.
    install -Dm444 usr/share/applications/aghub.desktop \
      $out/share/applications/aghub.desktop

    cp -r usr/share/icons $out/share/

    runHook postInstall
  '';

  # aghub shells out to `ccusage`, which upstream ships next to it in the
  # same .deb and resolves from PATH (or an AGHUB_CCUSAGE_BIN override).
  # Both binaries already land in the same $out/bin, so the lookup succeeds
  # once $out/bin is on PATH; make it explicit for the desktop-entry launch
  # path, which starts from a bare session environment.
  postFixup = ''
    wrapProgram $out/bin/aghub --prefix PATH : $out/bin
  '';

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        "--url"
        "https://github.com/AkaraChen/aghub/releases/download/v${finalAttrs.version}/aghub_${finalAttrs.version}_amd64.deb"
      ];
    };
  };

  meta = {
    description = "Unified configuration hub for AI coding agents";
    longDescription = ''
      Desktop GUI for managing MCP servers, skills and plugins across 22+
      AI coding agents (Claude Code, Codex, OpenCode, Cursor, ...).

      Repackaged from the upstream .deb release asset rather than built from
      source: the Tauri v2 + Rust + bun build is a large custom toolchain and
      upstream publishes no Nix expression. The .deb's bundled binaries are
      kept as-is; only the ELF interpreter and library rpaths are rewritten so
      they resolve against this system's WebKitGTK/GTK/OpenSSL.
    '';
    homepage = "https://github.com/AkaraChen/aghub";
    downloadPage = "https://github.com/AkaraChen/aghub/releases";
    changelog = "https://github.com/AkaraChen/aghub/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = [];
    platforms = ["x86_64-linux"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    mainProgram = "aghub";
  };
})
