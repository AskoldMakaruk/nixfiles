{
  config,
  lib,
  pkgs,
  ...
}:

{
  options = {
    batat.basic.enable = lib.mkEnableOption "enables basic programs";
  };

  config = lib.mkIf config.batat.basic.enable {

    nixpkgs.config = {
      allowUnfree = true;
    };

    environment.systemPackages = with pkgs; [
      anki-bin
      #dotnet-sdk
      dotnetCorePackages.sdk_9_0
      dotnet-ef
      telegram-desktop
      nix-output-monitor # nom. for build logs

      lazygit
      git

      #tools
      nettools
      usbutils

      yazi
      fzf
      zoxide
      dblab

      ghostty # terminal emulator
    ];
    # Install firefox.
    programs.firefox.enable = true;

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
