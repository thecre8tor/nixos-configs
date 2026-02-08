# Locale and internationalization settings
{ config, lib, pkgs, ... }:

{
  # Set your time zone
  time.timeZone = "Africa/Lagos";

  # Select internationalisation properties
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };
}
