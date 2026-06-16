# modules/audio.nix
#
# 音频核心 — Pipewire + ALSA + PulseAudio 兼容层
# nixpkgs: os-specific (系统级音频驱动)
{
  lossilk.audio = {
    nixos = {
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };
    };

    user.extraGroups = ["sound" "audio"];
  };
}
