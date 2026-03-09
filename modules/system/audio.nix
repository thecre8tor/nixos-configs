{
  config,
  lib,
  pkgs,
  ...
}:

{
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=0 power_save_controller=N
    options snd_hda_intel position_fix=1
    options snd_hda_codec_realtek model=103c:8895
  '';

  environment.etc."asound.conf".text = ''
    defaults.pcm.rate_converter "samplerate_best"
  '';

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [
          44100
          48000
        ];
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 1024;
        "default.clock.max-quantum" = 1024;
        "default.clock.force-quantum" = 1024;
        "default.clock.force-rate" = 48000;
      };
    };
  };
}
