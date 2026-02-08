# Audio configuration
{ config, lib, pkgs, ... }:

{
  # Enable sound with PipeWire
  # services.pulseaudio.enable = true;
  # OR
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };
}
