{inputs, ...}: {
  lossilk.dev._.lang._.nix.homeManager = {pkgs, ...}: {
    home.packages = [
      pkgs.nixd
      pkgs.nix-init
      pkgs.nix-inspect
      pkgs.nix-output-monitor
      pkgs.nix-tree
      pkgs.nix-update
      pkgs.nurl
      pkgs.statix
      inputs.nix-alien.packages.${pkgs.stdenv.hostPlatform.system}.nix-alien
    ];

    programs.nh = {
      enable = true;
      flake = "/home/loss/nix-config";
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 5 --keep-since 7d";
      };
    };
  };
}
