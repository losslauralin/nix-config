{lossilk, ...}: {
  lossilk.dev._.editors._.helix = {
    homeManager = {lib, ...}: {
      home.sessionVariables = {
        EDITOR = lib.mkDefault "hx";
        VISUAL = lib.mkDefault "hx";
        EDIR_EDITOR = lib.mkDefault "hx";
      };

      programs.helix = {
        enable = true;
        languages = {
          language-server.ucm = {
            command = "nc";
            args = [
              "localhost"
              "5757"
            ];
          };
          language = [
            {
              name = "unison";
              language-servers = ["ucm"];
            }
          ];
        };
        settings = {
          keys.normal = {
            X = "extend_line_above";
            C-h = "jump_view_left";
            C-j = "jump_view_down";
            C-k = "jump_view_up";
            C-l = "jump_view_right";
            C-r = ":reload";
            A-r = ":reset-diff-change";
            space."=" = ":format";
          };
          editor = {
            color-modes = true;
            cursorcolumn = true;
            cursorline = true;
            end-of-line-diagnostics = "error";
            inline-diagnostics.cursor-line = "hint";
            line-number = "relative";
            lsp.display-inlay-hints = true;
            soft-wrap.enable = true;
            indent-guides = {
              render = true;
              skip-levels = 1;
            };
            cursor-shape = {
              insert = "bar";
              normal = "block";
              select = "underline";
            };
            shell = [
              "bash"
              "-c"
            ];
            statusline = {
              left = [
                "mode"
                "spinner"
                "file-type"
                "diagnostics"
              ];
              center = ["file-name"];
              right = [
                "selections"
                "position"
                "separator"
                "spacer"
                "position-percentage"
              ];
              separator = "|";
            };
          };
        };
      };
    };
  };

  lossilk.dev._.editors._.helix._.with-tools = {
    includes = [
      lossilk.dev._.editors._.helix
    ];

    homeManager = {pkgs, ...}: {
      home.packages = [
        pkgs.lldb
        pkgs.nil
        pkgs.nixd
        pkgs.nixfmt
        pkgs.rust-analyzer
        pkgs.gopls
        pkgs.delve
        pkgs.golangci-lint-langserver
        pkgs.golangci-lint
        pkgs.ty
        pkgs.bash-language-server
        pkgs.typescript-language-server
        pkgs.lua-language-server
        pkgs.kotlin-language-server
      ];
    };
  };
}
