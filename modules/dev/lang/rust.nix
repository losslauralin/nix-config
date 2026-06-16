# modules/dev/lang/rust.nix
{inputs, ...}: {
  lossilk.dev._.lang._.rust = {
    nixos = {
      nixpkgs.overlays = [
        inputs.rust-overlay.overlays.default
      ];
    };

    homeManager = {pkgs, ...}: {
      home.packages = [
        pkgs.rust-bin.stable.latest.default
      ];
    };
  };
}
