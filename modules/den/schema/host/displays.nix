# modules/den/schema/host/displays.nix
#
# Host display metadata schema. Actual display values remain host specs; this file
# only owns the shared den.schema.host interface consumed by desktop/gaming Aspects.
{lib, ...}: let
  inherit (lib) mkOption types;

  displayType = types.submodule (
    {
      name,
      config,
      ...
    }: {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
          readOnly = true;
        };
        primary = mkOption {
          type = types.bool;
          default = false;
        };
        refresh = mkOption {
          type = types.float;
          default = 60.0;
        };
        width = mkOption {
          type = types.int;
          default = 1920;
        };
        height = mkOption {
          type = types.int;
          default = 1080;
        };
        x = mkOption {
          type = types.int;
          default = 0;
        };
        y = mkOption {
          type = types.int;
          default = 0;
        };
        scaling = mkOption {
          type = types.float;
          default = 1.0;
        };
        roundScaling = mkOption {
          type = types.int;
          default = builtins.ceil config.scaling;
          readOnly = true;
        };
        vrr = mkOption {
          type = types.enum [
            true
            false
            "on-demand"
          ];
          default = false;
        };
        wallpaper = mkOption {
          type = types.nullOr types.path;
          default = null;
        };
      };
    }
  );
in {
  den.schema.host = {config, ...}: let
    inherit (config) displays;
    displayList = builtins.attrValues displays;
    primaries = lib.filterAttrs (_: display: display.primary) displays;
    primaryList = builtins.attrValues primaries;
    primaryNames = lib.concatStringsSep ", " (lib.attrNames primaries);
  in {
    options.displays = mkOption {
      type = types.lazyAttrsOf displayType;
      default = {};
    };
    options.primaryDisplay = mkOption {
      type = types.nullOr (types.lazyAttrsOf types.raw);
      readOnly = true;
      default =
        if builtins.length displayList == 1
        then builtins.head displayList
        else if builtins.length primaryList == 0
        then null
        else if builtins.length primaryList > 1
        then builtins.throw "Multiple displays marked as primary: ${primaryNames}"
        else builtins.head primaryList;
    };
  };
}
