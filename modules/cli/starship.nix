{
  lossilk.cli._.starship.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.sd];

    programs.starship = {
      enable = true;
      # shell 集成由 HM programs 模块默认值处理（enableFishIntegration / enableZshIntegration 默认跟随 enable）。

      settings = {
        format = "$all";

        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](maroon)";
        };

        shell.disabled = false;
        jobs.disabled = true; # TODO: atuin 会在 prompt closure 期间创建 job，且 symbol_threshold 选项当前有 bug。

        # Jujutsu: https://github.com/jj-vcs/jj/wiki/Starship
        custom.jj = {
          command = ''
            jj log --revisions @ --limit 1 --ignore-working-copy --no-graph --color always  --template '
                separate(" ",
                  bookmarks.map(|x| truncate_end(10, x.name(), "…")).join(" "),
                  tags.map(|x| truncate_end(10, x.name(), "…")).join(" "),
                  surround("\"", "\"", truncate_end(24, description.first_line(), "…")),
                  if(conflict, "conflict"),
                  if(divergent, "divergent"),
                  if(hidden, "hidden"),
                )
              '
          '';
          when = "jj --ignore-working-copy root";
          symbol = "jj ";
        };

        custom.jjstate = {
          command = ''
            jj log -r@ -n1 --ignore-working-copy --no-graph -T "" --stat | tail -n1 | sd "(\d+) files? changed, (\d+) insertions?\(\+\), (\d+) deletions?\(-\)" ' ''${1}m ''${2}+ ''${3}-' | sd " 0." ""
          '';
          when = "jj --ignore-working-copy root";
        };

        git_branch.disabled = true;
        git_commit.disabled = true;
        git_state.disabled = true;
        git_metrics.disabled = true;
        git_status.disabled = true;

        # nerd-font-symbols preset
        aws.symbol = " ";
        buf.symbol = " ";
        bun.symbol = " ";
        c.symbol = " ";
        cpp.symbol = " ";
        cmake.symbol = " ";
        conda.symbol = " ";
        crystal.symbol = " ";
        dart.symbol = " ";
        deno.symbol = " ";
        directory.read_only = " 󰌾";
        docker_context.symbol = " ";
        elixir.symbol = " ";
        elm.symbol = " ";
        fennel.symbol = " ";
        fortran.symbol = " ";
        fossil_branch.symbol = " ";
        gcloud.symbol = " ";
        git_branch.symbol = " ";
        git_commit.tag_symbol = "  ";
        golang.symbol = " ";
        gradle.symbol = " ";
        guix_shell.symbol = " ";
        haskell.symbol = " ";
        haxe.symbol = " ";
        hg_branch.symbol = " ";
        hostname.ssh_symbol = " ";
        java.symbol = " ";
        julia.symbol = " ";
        kotlin.symbol = " ";
        lua.symbol = " ";
        memory_usage.symbol = "󰍛 ";
        meson.symbol = "󰔷 ";
        nim.symbol = "󰆥 ";
        nix_shell.symbol = " ";
        nodejs.symbol = " ";
        ocaml.symbol = " ";
        os.symbols = {
          Alpaquita = " ";
          Alpine = " ";
          AlmaLinux = " ";
          Amazon = " ";
          Android = " ";
          AOSC = " ";
          Arch = " ";
          Artix = " ";
          CachyOS = " ";
          CentOS = " ";
          Debian = " ";
          DragonFly = " ";
          Elementary = " ";
          Emscripten = " ";
          EndeavourOS = " ";
          Fedora = " ";
          FreeBSD = " ";
          Garuda = "󰛓 ";
          Gentoo = " ";
          HardenedBSD = "󰞌 ";
          Illumos = "󰈸 ";
          Ios = "󰀷 ";
          Kali = " ";
          Linux = " ";
          Mabox = " ";
          Macos = " ";
          Manjaro = " ";
          Mariner = " ";
          MidnightBSD = " ";
          Mint = " ";
          NetBSD = " ";
          NixOS = " ";
          Nobara = " ";
          OpenBSD = "󰈺 ";
          openSUSE = " ";
          OracleLinux = "󰌷 ";
          Pop = " ";
          Raspbian = " ";
          Redhat = " ";
          RedHatEnterprise = " ";
          RockyLinux = " ";
          Redox = "󰀘 ";
          Solus = "󰠳 ";
          SUSE = " ";
          Ubuntu = " ";
          Unknown = " ";
          Void = " ";
          Windows = "󰍲 ";
          Zorin = " ";
        };
        package.symbol = "󰏗 ";
        perl.symbol = " ";
        php.symbol = " ";
        pijul_channel.symbol = " ";
        pixi.symbol = "󰏗 ";
        python.symbol = " ";
        rlang.symbol = "󰟔 ";
        ruby.symbol = " ";
        rust.symbol = "󱘗 ";
        scala.symbol = " ";
        status.symbol = " ";
        swift.symbol = " ";
        xmake.symbol = " ";
        zig.symbol = " ";
      };
    };
  };
}
