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

    homeManager = {
      xdg.configFile."fcitx5/conf/classicui.conf".text = ''
        Vertical Candidate List=False
        WheelForPaging=True
        Font=Noto Sans CJK SC 16
        Theme=macos-light-blur
        DarkTheme=macos-dark-blur
        UseDarkTheme=True
        UseAccentColor=False
        EnableFractionalScale=True
      '';

      xdg.dataFile = {
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
            menu/alternative_select_labels: ["1.", "2.", "3.", "4.", "5.", "6."]
        '';

        "fcitx5/themes/macos-light-blur/theme.conf".text = ''
          [Metadata]
          Name=macOS Light Blur
          Version=1
          Author=lossilk
          Description=macOS-inspired translucent light theme

          [InputPanel]
          NormalColor=#000000
          HighlightColor=#ffffff
          HighlightBackgroundColor=#007aff
          HighlightCandidateColor=#ffffff
          EnableBlur=True
          BlurMask=blur-mask.svg
          FullWidthHighlight=False

          [InputPanel/ContentMargin]
          Left=7
          Right=7
          Top=7
          Bottom=7

          [InputPanel/TextMargin]
          Left=9
          Right=9
          Top=6
          Bottom=6

          [InputPanel/Background]
          Image=background.svg

          [InputPanel/Background/Margin]
          Left=16
          Right=16
          Top=16
          Bottom=16

          [InputPanel/Highlight]
          Image=highlight.svg

          [InputPanel/Highlight/Margin]
          Left=9
          Right=9
          Top=9
          Bottom=9

          [InputPanel/ShadowMargin]
          Left=6
          Right=6
          Top=6
          Bottom=6

          [Menu]
          NormalColor=#000000
          HighlightCandidateColor=#ffffff

          [Menu/Background]
          Image=background.svg

          [Menu/Background/Margin]
          Left=16
          Right=16
          Top=16
          Bottom=16

          [Menu/Highlight]
          Image=highlight.svg

          [Menu/Highlight/Margin]
          Left=9
          Right=9
          Top=9
          Bottom=9

          [Menu/ContentMargin]
          Left=7
          Right=7
          Top=7
          Bottom=7

          [Menu/TextMargin]
          Left=9
          Right=9
          Top=6
          Bottom=6
        '';

        "fcitx5/themes/macos-light-blur/background.svg".text = ''
          <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">
            <defs>
              <filter id="shadow" x="-50%" y="-50%" width="200%" height="200%">
                <feGaussianBlur stdDeviation="2"/>
              </filter>
            </defs>
            <rect x="6" y="8" width="36" height="34" rx="10" fill="#000000" fill-opacity="0.22" filter="url(#shadow)"/>
            <rect x="6" y="6" width="36" height="36" rx="10" fill="#ffffff" fill-opacity="0.69" stroke="#ffffff" stroke-opacity="0.72"/>
          </svg>
        '';

        "fcitx5/themes/macos-light-blur/highlight.svg".text = ''
          <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
            <rect x="1" y="1" width="30" height="30" rx="9" fill="#007aff"/>
          </svg>
        '';

        "fcitx5/themes/macos-light-blur/blur-mask.svg".text = ''
          <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">
            <rect x="6" y="6" width="36" height="36" rx="10" fill="#ffffff"/>
          </svg>
        '';

        "fcitx5/themes/macos-dark-blur/theme.conf".text = ''
          [Metadata]
          Name=macOS Dark Blur
          Version=1
          Author=lossilk
          Description=macOS-inspired translucent dark theme

          [InputPanel]
          NormalColor=#ffffffe6
          HighlightColor=#ffffff
          HighlightBackgroundColor=#007aff
          HighlightCandidateColor=#ffffff
          EnableBlur=True
          BlurMask=blur-mask.svg
          FullWidthHighlight=False

          [InputPanel/ContentMargin]
          Left=7
          Right=7
          Top=7
          Bottom=7

          [InputPanel/TextMargin]
          Left=9
          Right=9
          Top=6
          Bottom=6

          [InputPanel/Background]
          Image=background.svg

          [InputPanel/Background/Margin]
          Left=16
          Right=16
          Top=16
          Bottom=16

          [InputPanel/Highlight]
          Image=highlight.svg

          [InputPanel/Highlight/Margin]
          Left=9
          Right=9
          Top=9
          Bottom=9

          [InputPanel/ShadowMargin]
          Left=6
          Right=6
          Top=6
          Bottom=6

          [Menu]
          NormalColor=#ffffffe6
          HighlightCandidateColor=#ffffff

          [Menu/Background]
          Image=background.svg

          [Menu/Background/Margin]
          Left=16
          Right=16
          Top=16
          Bottom=16

          [Menu/Highlight]
          Image=highlight.svg

          [Menu/Highlight/Margin]
          Left=9
          Right=9
          Top=9
          Bottom=9

          [Menu/ContentMargin]
          Left=7
          Right=7
          Top=7
          Bottom=7

          [Menu/TextMargin]
          Left=9
          Right=9
          Top=6
          Bottom=6
        '';

        "fcitx5/themes/macos-dark-blur/background.svg".text = ''
          <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">
            <defs>
              <filter id="shadow" x="-50%" y="-50%" width="200%" height="200%">
                <feGaussianBlur stdDeviation="2"/>
              </filter>
            </defs>
            <rect x="6" y="8" width="36" height="34" rx="10" fill="#000000" fill-opacity="0.42" filter="url(#shadow)"/>
            <rect x="6" y="6" width="36" height="36" rx="10" fill="#000000" fill-opacity="0.15" stroke="#ffffff" stroke-opacity="0.18"/>
          </svg>
        '';

        "fcitx5/themes/macos-dark-blur/highlight.svg".text = ''
          <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
            <rect x="1" y="1" width="30" height="30" rx="9" fill="#007aff"/>
          </svg>
        '';

        "fcitx5/themes/macos-dark-blur/blur-mask.svg".text = ''
          <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">
            <rect x="6" y="6" width="36" height="36" rx="10" fill="#ffffff"/>
          </svg>
        '';
      };
    };
  };
}
