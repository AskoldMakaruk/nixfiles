{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  options = {
    batat.basic.enable = lib.mkEnableOption "enables basic stuff";
  };

  config = lib.mkIf config.batat.basic.enable {
    nixpkgs.config = {
      allowUnfree = true;
    };

    environment.systemPackages = with pkgs; [
      # nom. for nixos switch build logs
      nix-output-monitor
      # agenix tool for declarative secret management
      inputs.agenix.packages.${system}.default

      xdotool

      #tools
      nettools
      usbutils
      # cli folder navigator
      yazi
      fzf
      zoxide
      dblab
      tree
      ripgrep

      # websocket cli client
      claws

      ghostty
    ];

    # Set your time zone.
    time.timeZone = "Europe/Kyiv";

    # Select internationalisation properties.
    i18n.defaultLocale = "en_GB.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "uk_UA.UTF-8";
      LC_IDENTIFICATION = "uk_UA.UTF-8";
      LC_MEASUREMENT = "uk_UA.UTF-8";
      LC_MONETARY = "uk_UA.UTF-8";
      LC_NAME = "uk_UA.UTF-8";
      LC_NUMERIC = "uk_UA.UTF-8";
      LC_PAPER = "uk_UA.UTF-8";
      LC_TELEPHONE = "uk_UA.UTF-8";
      LC_TIME = "uk_UA.UTF-8";
    };
  };
}
