# modules/gaming.nix
#
# Domain: 游戏圈子 — Steam/Lutris 等集成开关
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
        pkgs.cartridges
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
      lossilk.gaming._.replays
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
        pkgs.deadlock-mod-manager
        pkgs.goverlay
        pkgs.gpu-screen-recorder-gtk
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

  lossilk.gaming._.replays.homeManager = {
    lib,
    pkgs,
    ...
  }: {
    home.packages = [
      pkgs.gpu-screen-recorder
    ];

    systemd.user.services.gpu-screen-recorder = {
      Unit.Description = "gpu-screen-recorder replay service";
      Install.WantedBy = ["graphical-session.target"];
      Service.ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/Videos/Replays";
      Service.ExecStart = "${lib.getExe pkgs.gpu-screen-recorder} -w portal -f 60 -r 60 -k av1 -a 'default_output' -a 'default_input' -c mp4 -q high -o %h/Videos/Replays -restore-portal-session yes -v no";
    };
  };
}
