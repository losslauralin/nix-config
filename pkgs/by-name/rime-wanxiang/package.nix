{
  lib,
  fetchurl,
  stdenvNoCC,
  nix-update-script,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "rime-wanxiang";
  version = "17.9.1";

  srcs = [
    (fetchurl {
      # 墨奇辅助码增强版 (Pro) 完整配置包: 含词库/schema/lua, 支持任意双拼挂载.
      url = "https://github.com/amzxyz/rime-wanxiang/releases/download/v${finalAttrs.version}/rime-wanxiang-moqi-fuzhu.zip";
      hash = "sha256-WqcTaNQkpV4buXBQcQQ0AT+NHw+m5u01ayrk28xnVpg=";
    })
    (fetchurl {
      # 大模型语法包 (必装组件): 所有版本用户均必须下载, 与方案文件放一起.
      # 上游只有 LTS release tag, 内容不定期覆盖更新, hash 失效时重新 prefetch.
      url = "https://github.com/amzxyz/RIME-LMDG/releases/download/LTS/wanxiang-lts-zh-hans.gram";
      hash = "sha256-FjVYgAbXnMaVX7zz2N4Sgio2hW61QIc1qLSilSsWyt8=";
    })
  ];

  nativeBuildInputs = [unzip];

  unpackPhase = ''
    runHook preUnpack

    unzip -q "$(echo $srcs | cut -d' ' -f1)" -d wanxiang
    cp "$(echo $srcs | cut -d' ' -f2)" wanxiang/wanxiang-lts-zh-hans.gram

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/rime-data
    cp -r wanxiang/. $out/share/rime-data/

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Wanxiang Rime data (Moqi auxiliary codes) with LTS grammar model";
    longDescription = ''
      万象拼音 Pro (墨奇辅助码) 完整配置包, 直接来自上游 GitHub release:
      rime-wanxiang-moqi-fuzhu.zip, 加上 RIME-LMDG LTS release 的
      wanxiang-lts-zh-hans.gram 大模型语法包 (nixpkgs 不打包此文件).

      双拼类型通过 wanxiang_pro.schema.yaml 的
      `wanxiang_algebra:/pro/<双拼方案>` 切换 (默认自然码).
    '';
    homepage = "https://github.com/amzxyz/rime-wanxiang";
    downloadPage = "https://github.com/amzxyz/rime-wanxiang/releases";
    changelog = "https://github.com/amzxyz/rime-wanxiang/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.cc-by-40;
    maintainers = [];
    platforms = lib.platforms.all;
  };
})
