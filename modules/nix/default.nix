# 二进制缓存。Nix 按列表顺序依次查询, 第一个命中的生效, 所以顺序即优先级:
#   1. 第三方 cachix —— 只有它们才有 nix-community / catppuccin / numtide 的构建产物
#      (den / nixos-hardware / noctalia / umbriel 这类上游包 nixpkgs 官方缓存里没有)。
#   2. cache.nixos.org —— 官方, 覆盖绝大多数 nixpkgs (含 unstable 里的常见包)。
#   3. 国内镜像 —— 只镜像 cache.nixos.org, 放最后兜底; 放前面会白问一轮。
#
# 缓存来源都已经官方核实, 不要凭记忆加 key:
#   - nix-community: https://nix-community.org/cache/
#   - catppuccin:    上游 `catppuccin.cache.enable` 选项 (modules/desktop/appearance/catppuccin.nix)
#   - numtide:       https://cache.numtide.com (已从 cachix 迁移, 不再是 numtide.cachix.org)
let
  substituters = [
    "https://nix-community.cachix.org"
    "https://catppuccin.cachix.org"
    "https://cache.numtide.com"
    "https://cache.nixos.org/"
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://mirrors.cernet.edu.cn/nix-channels/store"
    "https://mirror.sjtu.edu.cn/nix-channels/store"
    "https://mirrors.bfsu.edu.cn/nix-channels/store"
    "https://mirror.nju.edu.cn/nix-channels/store"
    "https://mirror.iscas.ac.cn/nix-channels/store"
  ];

  # 只列第三方 key。cache.nixos.org-1 必须由这里显式带上: 下面用 mkForce 接管
  # 整个列表, 不依赖 nixpkgs 默认值 (否则默认值会被丢弃)。
  trustedPublicKeys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
  ];
in {
  lossilk.nix.nixos = {
    pkgs,
    lib,
    ...
  }: {
    nix = {
      channel.enable = false;
      nixPath = ["nixpkgs=${pkgs.path}"];

      extraOptions = ''
        connect-timeout = 5
        log-lines = 50
        min-free = 128000000
        max-free = 1000000000
        fallback = true
      '';
      optimise.automatic = true;

      settings = {
        trusted-users = ["root" "@wheel"];
        auto-optimise-store = true;
        experimental-features = ["nix-command" "flakes"];
        warn-dirty = false;
        tarball-ttl = 60 * 60 * 24;
        # 列表型选项在模块系统里拼接合并。nixpkgs 默认已带 cache.nixos.org 的
        # URL 与公钥, 某些模块还会再追加一次; 这里去重, 避免重复查询同一个缓存。
        substituters = lib.mkForce (lib.unique substituters);
        trusted-public-keys = lib.mkForce (lib.unique trustedPublicKeys);
        builders-use-substitutes = true;
      };
    };
  };
}
