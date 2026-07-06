# modules/desktop/input/fcitx5-rime-wanxiang.nix
#
# fcitx5 + Rime + 万象拼音 PRO: 小鹤双拼 + 墨奇辅码词库。
# `直接辅助` 只决定辅码跟在双拼后直接输入; 辅码类型由本地包里的
# Arch Linux CN `*-moqi-fuzhu` 数据/词库决定。
{inputs, ...}: {
  lossilk.desktop._.input._.fcitx5-rime-wanxiang = {
    nixos = {pkgs, ...}: let
      rime-wanxiang = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.rime-wanxiang;
    in {
      i18n.inputMethod = {
        enable = true;
        type = "fcitx5";
        fcitx5.addons = [
          pkgs.fcitx5-rime
          rime-wanxiang
        ];
      };

      environment.systemPackages = [pkgs.kdePackages.fcitx5-configtool];
    };

    homeManager.xdg.dataFile = {
      "fcitx5/rime/default.custom.yaml".text = ''
        patch:
          __include: wanxiang_suggested_default:/
          schema_list:
            - schema: wanxiang_pro
      '';

      "fcitx5/rime/wanxiang_pro.custom.yaml".text = ''
        patch:
          speller/algebra:
            __patch:
              - wanxiang_algebra:/pro/小鹤双拼
              - wanxiang_algebra:/pro/直接辅助
          menu/page_size: 6
      '';
    };
  };
}
