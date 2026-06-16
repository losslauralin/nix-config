# modules/dev/workflow/ansible.nix
#
# Ansible — 自动化运维 (nixpkgs: development/tools/misc)
{
  lossilk.dev._.workflow._.ansible.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.ansible];
  };
}
