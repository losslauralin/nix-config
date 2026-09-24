{
  inputs,
  lossilk,
  ...
}: {
  lossilk.gaming._.min = {host, ...}: let
    display = host.primaryDisplay;
  in {
    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: {
      boot.kernelModules = ["ntsync"];
      hardware.graphics.enable32Bit = true;

      services.udev.packages = [
        (pkgs.writeTextFile {
          name = "ntsync-udev-rules";
          text = ''KERNEL=="ntsync", MODE="0660", TAG+="uaccess"'';
          destination = "/etc/udev/rules.d/70-ntsync.rules";
        })
      ];

      assertions = [
        {
          assertion = lib.versionAtLeast config.boot.kernelPackages.kernel.version "6.14";
          message = "lossilk.gaming._.min requires Linux 6.14+ for ntsync.";
        }
      ];

      environment.systemPackages = [
        pkgs.heroic
        pkgs.umu-launcher
      ];

      programs = {
        steam = {
          enable = true;
          extraCompatPackages = [
            pkgs.proton-ge-bin
            pkgs.steamtinkerlaunch
          ];
        };

        gamescope = {
          enable = true;
          args = lib.optionals (display != null) ([
              "-W ${toString display.width}"
              "-H ${toString display.height}"
              "-r ${toString display.refresh}"
              "-O ${display.name}"
              "-f"
            ]
            ++ lib.optionals (display.vrr != false) [
              "--adaptive-sync"
            ]);
        };
      };
    };
  };

  lossilk.gaming._.max = {
    includes = [
      lossilk.gaming._.min
    ];

    nixos = {pkgs, ...}: {
      imports = [
        inputs.nix-gaming.nixosModules.platformOptimizations
        inputs.nix-gaming.nixosModules.pipewireLowLatency
      ];

      hardware = {
        opentabletdriver.enable = true;
        graphics.extraPackages = [
          inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}.low-latency-layer
        ];
      };

      services.pipewire.lowLatency = {
        enable = true;
        quantum = 512;
      };

      programs.steam = {
        platformOptimizations.enable = true;
        remotePlay.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
      };

      environment.systemPackages = [
        pkgs.goverlay
        pkgs.lsfg-vk
        pkgs.lsfg-vk-ui
        pkgs.ludusavi
        pkgs.mangohud
        pkgs.protonplus
        pkgs.protontricks
        pkgs.r2modman
        pkgs.winetricks
      ];
    };
  };
}
