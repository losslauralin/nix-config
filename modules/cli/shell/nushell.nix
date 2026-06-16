# modules/cli/shell/nushell.nix
#
# nushell Selection Variant —— 选择 Nushell 同时带上 shell Family Root 与 user-shell battery。
{
  den,
  lossilk,
  ...
}: {
  lossilk.cli._.shell._.nushell = {
    includes = [
      lossilk.cli._.shell
      (den.provides.user-shell "nushell")
    ];

    homeManager = {
      lib,
      pkgs,
      ...
    }: {
      programs = {
        nushell = {
          enable = true;
          package = pkgs.nushell.override {
            additionalFeatures = _: [
              "full"
              "mcp"
            ];
          };
          shellAliases = {
            o = "xdg-open";
            l = "ls";
            la = "ls -a";
            ll = "ls -al";
            tree = "eza -T";
            em = "job spawn { emacsclient -c . }";
            e = "emacsclient -r";
          };
          settings = {
            show_banner = false;
            rm.always_trash = true;
            display_errors = {
              exit_code = false;
              termination_signal = true;
            };
            completions.algorithm = "substring";
          };
          extraConfig = lib.mkAfter ''
            if "INSIDE_EMACS" in $env {
              $env.EDITOR = "emacsclient -r"
              $env.VISUAL = "emacsclient -r"
            }

            # zoxide 对尾部 / 的处理不稳定，进入前先规整路径。
            def --env --wrapped __cd_wrapper (...rest: string) {
              let trimmed = if ($rest | is-empty) {
                $rest
              } else {
                $rest | update ($rest | length | $in - 1) { |s|
                  let t = $s | str trim -r -c '/'
                  if ($t | is-empty) { '/' } else { $t }
                }
              }
              __zoxide_z ...$trimmed
            }
            alias cd = __cd_wrapper

            def --wrapped nxs (...input: string) {
              let flags = $input | where ($it | str starts-with "-")
              let packages = $input | where not ($it | str starts-with "-")
              let formatted_packages = $packages | each {|package|
                if not ($package | str contains "#") {
                  return $"nixpkgs#($package)"
                }
                $package
              }
              ^nix shell ...$formatted_packages ...$flags
            }
          '';
          extraLogin = ''
            # distrobox 会把 FHS 路径插到前面；这里保留其优先级，避免宿主路径抢先。
            if "DISTROBOX_ENTER_PATH" in $env {
              let fhs = $env.PATH | where {|p|
                ($p | str starts-with "/usr/") or ($p == "/bin") or ($p == "/sbin")
              }
              let rest = $env.PATH | where {|p|
                not (($p | str starts-with "/usr/") or ($p == "/bin") or ($p == "/sbin"))
              }
              $env.PATH = ($fhs | append $rest)
            }
          '';
        };

        carapace = {
          enable = true;
          enableNushellIntegration = true;
        };
      };
    };
  };
}
