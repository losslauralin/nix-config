{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  atk,
  cairo,
  curlMinimal,
  fontconfig,
  gdk-pixbuf,
  glib,
  gobject-introspection,
  gtk3,
  harfbuzz,
  jre_minimal,
  keybinder3,
  libayatana-appindicator,
  libepoxy,
  libsecret,
  pango,
  zlib,
  nix-update-script,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "karing";
  version = "1.2.21.2402";

  src = fetchurl {
    url = "https://github.com/KaringX/karing/releases/download/v${finalAttrs.version}/karing_${finalAttrs.version}_linux_amd64.deb";
    hash = "sha256-7f1wkB2vZyKUN0btjMTnikxO4jjpIVq9wk8TK9onkZo=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
  ];

  preFixup = ''
    addAutoPatchelfSearchPath ${jre_minimal}/lib/server
  '';

  buildInputs = [
    atk
    cairo
    curlMinimal
    fontconfig
    gdk-pixbuf
    glib
    gobject-introspection
    gtk3
    harfbuzz
    keybinder3
    (lib.getLib stdenv.cc.cc)
    libayatana-appindicator
    libepoxy
    libsecret
    pango
    zlib
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg -X $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share
    cp -r opt/karing $out/share/karing
    cp -r usr/share/applications usr/share/icons $out/share/

    ln -s $out/share/karing/karing $out/bin/karing
    ln -s $out/share/karing/karingService $out/bin/karingService

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {};

  meta = {
    changelog = "https://github.com/KaringX/karing/releases/tag/v${finalAttrs.version}";
    description = "Simple and powerful proxy utility with routing rules for Clash and sing-box";
    homepage = "https://github.com/KaringX/karing";
    license = with lib.licenses; [
      gpl3Plus
      unfree
    ];
    mainProgram = "karing";
    platforms = ["x86_64-linux"];
    sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    maintainers = [];
  };
})
