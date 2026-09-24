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
  glib-networking,
  dbus,
  cairo,
  gdk-pixbuf,
  # Not linked against: only its compiled GSettings schemas, which the wrapper
  # puts on XDG_DATA_DIRS (see postFixup).
  gsettings-desktop-schemas,
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
    glib-networking
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
  #
  # GIO_EXTRA_MODULES: WebKitGTK 通过 GIO 发网络请求, 而 NixOS 默认不提供
  # glib-networking, 于是 GIO 的 TLS 后端退化成 GDummyTlsBackend
  # (supports_tls = false), **任何 HTTPS 请求都发不出去**。表现是应用能开、
  # 文字和布局正常, 但所有远程图片/图标静默不渲染 —— "Resources" 面板里
  # 那些 agent 图标就是这样丢的。同时缺的还有 gnome / libproxy 两个
  # proxy-resolver 扩展, 所以系统代理对 WebKit 也不可见。
  #
  # 这是 NixOS 侧的已知问题 (NixOS/nixpkgs#367378), 解法就是补 glib-networking;
  # 该 issue 里 "images and icons are not displayed" 的症状与本包一致。
  #
  # 用 --suffix 而非 --set: 会话里已有 GIO_EXTRA_MODULES (dconf 的 modules 目录),
  # --set 会把它挤掉。GIO 会合并该变量里的所有目录, 顺序不影响谁能胜出
  # (gnutls 优先级 0, dummy 是 -100)。
  #
  # XDG_DATA_DIRS: GTK 3 and WebKitGTK do not read the desktop's font, DPI or
  # scaling settings from anywhere else -- they come from GSettings, and the
  # schemas live in gtk3 (org.gtk.Settings.*) and gsettings-desktop-schemas
  # (org.gnome.desktop.interface). NixOS only puts *system profile* packages'
  # schemas on XDG_DATA_DIRS (as $out/share/gsettings-schemas/<name>), so a
  # store package that runs GTK without adding its own schema directories
  # silently falls back to compiled-in defaults.
  #
  # Documented symptom of exactly that (see the cc-switch NixOS packaging,
  # github.com/HYBB-rash/cc-switch-nix-webkitgtk-fix, same Tauri + WebKitGTK
  # shape): the whole UI renders too small, the top of the window is cut off
  # and most of the window stays blank. Measured on aghub 1.9.1 here: the
  # sidebar is `w-60` (240px) in the app's own CSS but rendered ~160px wide,
  # i.e. the CSS root font size had fallen to ~10.6px instead of 16px -- so
  # every rem-based size in the app shrank by a third. Reproduced regardless
  # of the window size, and it is the classic NixOS "Tauri app looks tiny" bug
  # rather than anything aghub does wrong.
  #
  # --prefix, not --set: the session's own XDG_DATA_DIRS (system profile, user
  # profile, flatpak exports) must stay reachable. Schema lookup merges every
  # directory, so order does not decide who wins.
  postFixup = ''
    # The two schema directories are addressed as <pkg>/share/gsettings-schemas/<name>
    # (the layout glib's setup hook installs). Check them here instead of trusting
    # the path: a stale layout would leave the wrapper pointing at nothing and the
    # fix below would silently do nothing.
    test -d ${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}/glib-2.0/schemas
    test -d ${gtk3}/share/gsettings-schemas/${gtk3.name}/glib-2.0/schemas

    wrapProgram $out/bin/aghub \
      --prefix PATH : $out/bin \
      --suffix GIO_EXTRA_MODULES : ${glib-networking}/lib/gio/modules \
      --prefix XDG_DATA_DIRS : ${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}:${gtk3}/share/gsettings-schemas/${gtk3.name}
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
      they resolve against this system's WebKitGTK/GTK/OpenSSL, and the wrapper
      supplies GIO_EXTRA_MODULES (glib-networking) that NixOS does not put on
      GIO's search path by default.
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
