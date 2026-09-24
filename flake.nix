{
  description = "A personal Nix configuration for NixOS and Home Manager.";

  outputs = inputs: inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./modules);

  nixConfig = {
    # 与 modules/nix/default.nix 的 nix.settings 保持一致: 前者管系统 rebuild,
    # 这里管 flake 求值 / 裸 `nix build` 阶段。缓存可用的顺序同理 —— 先第三方
    # (它们才有上游包的产物), 国内镜像只镜像 cache.nixos.org, 不必在此重复列出。
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://catppuccin.cachix.org"
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";
    den.url = "github:denful/den";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    arion = {
      url = "github:hercules-ci/arion";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-index-database.follows = "nix-index-database";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.blueprint.inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    };
    # Paseo: daemon + 客户端的自托管 AI coding agent 界面。上游 flake 的
    # nixpkgs 不 follow 的话会引入第二份 nixpkgs (体积翻倍 + Electron/系统库
    # 版本可能分叉), 所以照 umbriel 的写法统一 follows。
    # 注意: 因为它构建自源码 (buildNpmPackage), 换了 nixpkgs 后上游的
    # nix/npm-deps.hash 未必匹配 —— 见 modules/ai/paseo.nix 的 npmDepsHash。
    paseo = {
      url = "github:getpaseo/paseo";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    nix-colors = {
      url = "github:misterio77/nix-colors";
      inputs.nixpkgs-lib.follows = "flake-parts/nixpkgs-lib";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    # Umbriel compositor。nixpkgs 里的版本钉在旧 commit 上 (且 nixpkgs 的
    # programs.umbriel 模块缺 systemd/portal 接线), 所以直接引上游 flake:
    # 拿到最新源码 + 官方 nixosModules (会 disabledModules 掉 nixpkgs 的同名模块)。
    # follows 让上游共用本 flake 的 nixpkgs —— 只保留一份, 且与系统其余部分一致。
    umbriel = {
      url = "github:noctalia-dev/umbriel";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    make-shell.url = "github:nicknovitski/make-shell";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
