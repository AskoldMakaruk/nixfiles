{
  inputs,
  config,
  lib,
  pkgs,
  users,
  ...
}:

{
  options = {
    batat.basic.enable = lib.mkEnableOption "enables basic programs";
  };

  config = lib.mkIf config.batat.console.enable {

    nixpkgs.config = {
      allowUnfree = true;
    };

    environment.systemPackages = with pkgs; [
      dotnetCorePackages.sdk_9_0
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

  };
}
