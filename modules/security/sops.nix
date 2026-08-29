# sops-nix 集中配置 —— 所有切面的密钥解密共享此模块。
# 解密用 SSH host key (/etc/ssh/ssh_host_ed25519_key)。
{inputs, ...}: {
  lossilk.security._.sops = {
    nixos = {
      imports = [inputs.sops-nix.nixosModules.sops];
      sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    };

    homeManager = {
      imports = [inputs.sops-nix.homeManagerModules.sops];
      sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    };
  };
}
