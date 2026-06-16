# modules/networking/ssh.nix
#
# SSH remote-access concerns. Agent and server are explicit children; no generic ssh
# root Aspect exists because there is no shared SSH behavior to activate implicitly.
{
  lossilk.networking._.ssh._.agent.homeManager.services.ssh-agent.enable = true;

  lossilk.networking._.ssh._.server.nixos = {
    services.openssh = {
      enable = true;
      openFirewall = true;
    };
  };
}
