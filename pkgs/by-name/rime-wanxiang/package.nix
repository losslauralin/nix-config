{
  lib,
  fetchurl,
  stdenvNoCC,
  nix-update-script,
  zstd,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "rime-wanxiang";
  version = "16.0.1";

  srcs = [
    (fetchurl {
      url = "https://repo.archlinuxcn.org/x86_64/rime-wanxiang-gram-zh-hans-2:20260705.144844-1-any.pkg.tar.zst";
      hash = "sha256-Pru+Q6UHnjXPIvajlqMjatDeyxH6qmAnQuv/lfMm3S0=";
    })
    (fetchurl {
      url = "https://repo.archlinuxcn.org/x86_64/rime-wanxiang-pro-data-${finalAttrs.version}-1-any.pkg.tar.zst";
      hash = "sha256-KK1rwPN3ytfkb7fQiiuvpyDoztn6SO3Q5aD8n3OYhZU=";
    })
    (fetchurl {
      url = "https://repo.archlinuxcn.org/x86_64/rime-wanxiang-pro-dict-${finalAttrs.version}-1-any.pkg.tar.zst";
      hash = "sha256-VMhM4tFVeAoeN/1rXw7Hh9ZntOzwlaZ0jc+c+Eq7ItA=";
    })
    (fetchurl {
      url = "https://repo.archlinuxcn.org/x86_64/rime-wanxiang-pro-dict-moqi-fuzhu-${finalAttrs.version}-1-any.pkg.tar.zst";
      hash = "sha256-Bsnw2ic4zeGTfcRjezYzy243CI9JTebz823vNz/+SeI=";
    })
    (fetchurl {
      url = "https://repo.archlinuxcn.org/x86_64/rime-wanxiang-pro-data-moqi-fuzhu-${finalAttrs.version}-1-any.pkg.tar.zst";
      hash = "sha256-K0yFEwahr562iXuYQZ6jed5iT4j2NCipnlFGbta7O4w=";
    })
    (fetchurl {
      url = "https://repo.archlinuxcn.org/x86_64/rime-wanxiang-pro-flypy-${finalAttrs.version}-1-any.pkg.tar.zst";
      hash = "sha256-FQw9RHWj+KuatK645bUNCl/nYWRMiEmcSlKPSrYrJXQ=";
    })
  ];

  nativeBuildInputs = [zstd];

  unpackPhase = ''
    runHook preUnpack

    for src in $srcs; do
      tar --extract --file "$src"
    done

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share
    cp -r usr/share/rime-data $out/share/

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Wanxiang Pro Rime data for flypy with Moqi auxiliary codes";
    longDescription = ''
      万象拼音 PRO data assembled from the Arch Linux CN package split:
      rime-wanxiang-pro-flypy for 小鹤双拼, rime-wanxiang-pro-*-moqi-fuzhu
      for 墨奇辅助码 data and dictionaries, plus the shared Wanxiang data and
      grammar model.

      `wanxiang_algebra:/pro/直接辅助` is an input expansion rule: it makes the
      auxiliary code carried by the installed dictionaries directly typeable
      after the double-pinyin code. It does not choose the auxiliary-code type;
      the Moqi type comes from the installed `*-moqi-fuzhu` data and dictionary
      payloads.
    '';
    homepage = "https://github.com/amzxyz/rime-wanxiang";
    downloadPage = "https://repo.archlinuxcn.org/x86_64/";
    changelog = "https://github.com/amzxyz/rime-wanxiang/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.cc-by-40;
    maintainers = [];
    platforms = lib.platforms.all;
  };
})
