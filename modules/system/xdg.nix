# modules/system/xdg.nix
#
# XDG Base Directory 与常见工具路径清理。
{
  lossilk.system._.xdg = {
    nixos.xdg.terminal-exec.enable = true;

    homeManager = {config, ...}: {
      xdg = {
        enable = true;
        autostart = {
          enable = true;
          readOnly = true;
        };
        userDirs = {
          enable = true;
          createDirectories = true;
          setSessionVariables = true;
          desktop = null;
          templates = null;
          music = null;
          publicShare = null;
          projects = "${config.home.homeDirectory}/projects";
        };
      };

      home.sessionVariables = {
        ANDROID_USER_HOME = "${config.xdg.dataHome}/android";
        BUN_INSTALL_GLOBAL_DIR = "${config.xdg.dataHome}/bun";
        BUN_INSTALL_BIN = "${config.home.homeDirectory}/.local/bin";
        CARGO_HOME = "${config.xdg.dataHome}/cargo";
        CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";
        DOTNET_CLI_HOME = "${config.xdg.dataHome}/dotnet";
        GOPATH = "${config.xdg.dataHome}/go";
        GRADLE_USER_HOME = "${config.xdg.dataHome}/gradle";
        _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.configHome}/java";
        LESSHISTFILE = "${config.xdg.cacheHome}/less/history";
        MPLAYER_HOME = "${config.xdg.configHome}/mplayer";
        NODE_REPL_HISTORY = "${config.xdg.stateHome}/node_repl_history";
        NPM_CONFIG_INIT_MODULE = "${config.xdg.configHome}/npm/config/npm-init.js";
        NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm";
        NPM_CONFIG_PREFIX = "${config.xdg.stateHome}/npm";
        NXC_PATH = "${config.xdg.configHome}/nxc";
        NUGET_PACKAGES = "${config.xdg.cacheHome}/NuGetPackages";
        OCTAVE_HISTFILE = "${config.xdg.cacheHome}/octave-hsts";
        OCTAVE_SITE_INITFILE = "${config.xdg.configHome}/octave/octaverc";
        STACK_ROOT = "${config.xdg.dataHome}/stack";
        PI_CODING_AGENT_DIR = "${config.xdg.configHome}/pi/agent";
        PYTHON_HISTORY = "${config.xdg.configHome}/python/history";
        WINEPREFIX = "${config.xdg.dataHome}/wine";
        XCOMPOSECACHE = "${config.xdg.cacheHome}/X11/xcompose";
        _Z_DATA = "${config.xdg.dataHome}/z";
      };
    };
  };
}
