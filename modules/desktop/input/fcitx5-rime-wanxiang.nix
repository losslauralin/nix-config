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
          (pkgs.fcitx5-rime.override {
            rimeDataPkgs = [rime-wanxiang];
          })
        ];
      };

      environment.systemPackages = [pkgs.kdePackages.fcitx5-configtool];

      # NixOS 的 fcitx5 模块只把 Qt6 插件目录写进 QT_PLUGIN_PATH
      # (nixos/modules/i18n/input-method/fcitx5.nix), 于是 Qt5 程序找不到
      # fcitx5-qt5 的 platforminputcontext 插件; 自带 Qt5 的闭源程序 (腾讯会议)
      # 尤其明显 —— 它的 wrapper 会把 QT_PLUGIN_PATH 前缀成自己 bundle 的插件目录,
      # 只能靠继承值补上插件。列表类型的 environment.variables 在模块系统里按
      # 拼接合并, 所以这里追加一项不会覆盖模块写入的 Qt6 目录。
      environment.variables.QT_PLUGIN_PATH = [
        "${pkgs.libsForQt5.fcitx5-qt}/${pkgs.libsForQt5.qtbase.qtPluginPrefix}"
      ];
    };

    homeManager = {
      pkgs,
      lib,
      ...
    }: {
      # rime 的 schema 编译缓存不在 Nix 管理范围内, 且 librime 只按 mtime 判断
      # 是否需要重新部署; nix store 文件 mtime 恒为 0, 所以数据包版本变化时
      # rime 不会自动重建 $HOME/.local/share/fcitx5/rime/build/.
      # 这里用 stamp 记录数据包 store path, 变化时清一次缓存让 rime 重新部署.
      home.activation.rimeWanxiangDataChanged = lib.hm.dag.entryAfter ["writeBoundary"] ''
        rimeDir="$HOME/.local/share/fcitx5/rime"
        stamp="$rimeDir/.wanxiang-data"
        dataPath="${inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.rime-wanxiang}"
        if [ "$(cat "$stamp" 2>/dev/null)" != "$dataPath" ]; then
          run --silence rm -rf "$rimeDir/build"
          run mkdir -p "$rimeDir"
          run --quiet sh -c 'printf "%s\n" "$1" > "$2"' _ "$dataPath" "$stamp"
        fi
      '';

      # 触发键只保留 fcitx5 内建的 `Control+space` (还有 Zenkaku_Hankaku / Hangul),
      # 清掉那两个用 Super 的全局键。它们是内建默认, 不写就一直在用:
      #   EnumerateGroupForwardKeys  = Super+space        (切到下一输入法组)
      #   EnumerateGroupBackwardKeys = Super+Shift+space
      # 而 Umbriel 内建键位把 Mod+Space 用作 launcher/概览类动作, 于是同一个 chord
      # 两个消费者: 按 Mod+Space 既切输入法组, 又触发 compositor 动作。
      #
      # 空串 = 清空该列表 (fcitx5 的 list 型选项以 `Key=` 无值表示空, 见上游
      # globalconfig.cpp 与 fcitx5 自己写出的 config)。
      # TriggerKeys 故意不写 —— fcitx5 按 `partial` 部分加载本文件, 没写的键回退到
      # 内建默认, 所以 Control+space 仍然是 rime 的触发键。
      #
      # 不要改成 HM 的 `i18n.inputMethod.fcitx5.settings.globalOptions`: 那会让 HM
      # 在 `~/.config/fcitx5` 放**整个目录**的 linkFarm, 而该目录是 fcitx5 运行时
      # 自己写的真实目录 (profile / conf/notifications.conf / cached_layouts),
      # 激活时报 `Existing file '/home/loss/.config/fcitx5' would be clobbered` 而失败。
      # 本切面一直按文件管理 fcitx5 配置 (classicui.conf / rime/*), 这里保持一致。
      xdg.configFile."fcitx5/config".text = ''
        [Hotkey]
        EnumerateGroupForwardKeys=
        EnumerateGroupBackwardKeys=
      '';

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
