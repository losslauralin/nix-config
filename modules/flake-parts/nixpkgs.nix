{
  inputs,
  withSystem,
  ...
}: {
  systems = ["x86_64-linux"];

  imports = [
    inputs.pkgs-by-name-for-flake-parts.flakeModule
  ];

  perSystem = {system, ...}: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [];
      config = {
        allowUnfreePredicate = _pkg: true;
      };
    };

    pkgsDirectory = ../../pkgs/by-name;
  };

  flake.overlays = {
    default = _final: prev:
      withSystem prev.stdenv.hostPlatform.system ({config, ...}:
        config.packages);
  };
}
