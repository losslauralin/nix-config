# modules/dev/editors/emacs.nix
#
# Emacs (CLI `-nw` 或 GUI 窗口, 作为开发特征统一管理)
{inputs, ...}: {
  lossilk.dev._.editors._.emacs.homeManager = {pkgs, ...}: let
    system = pkgs.stdenv.hostPlatform.system;
    emacs = inputs.emacs-overlay.packages.${system}.emacs-unstable-pgtk;
    epkgs = pkgs.emacsPackagesFor emacs;

    ghostelModule = pkgs.fetchurl {
      url = "https://github.com/dakra/ghostel/releases/download/v0.14.0/ghostel-module-x86_64-linux.so";
      hash = "sha256-iALk4pAVTk/vG6CDSUCpCgrNzMBbORBwEgKo0bRRiwI=";
    };

    ghostel = epkgs.trivialBuild {
      pname = "ghostel";
      version = "0.14.0";
      src = pkgs.fetchFromGitHub {
        owner = "dakra";
        repo = "ghostel";
        rev = "5280db2fa1b0265ece41275d96f6c4b046e2b166";
        hash = "sha256-hLcIJj8GGdrswxlabYovS2/OWCahqCiFA4WWJJn2j6g=";
      };
      nativeBuildInputs = [
        pkgs.autoPatchelfHook
      ];
      preBuild = ''
        rm -f evil-ghostel.el ghostel-evil.el
      '';
      postInstall = ''
        install -m755 ${ghostelModule} $out/share/emacs/site-lisp/ghostel-module.so
      '';
    };
  in {
    services.emacs = {
      enable = true;
      client.enable = true;
      startWithUserSession = "graphical";
    };

    programs.emacs = {
      enable = true;
      package = emacs;
      extraPackages = epkgs: [
        epkgs.treesit-grammars.with-all-grammars
        epkgs.tree-sitter-langs
        epkgs.jinx
        epkgs.xeft
        epkgs.vterm
        ghostel
      ];
    };

    home.packages = [
      pkgs.pandoc
      pkgs.emacs-lsp-booster
      pkgs.to-html
    ];
  };
}
