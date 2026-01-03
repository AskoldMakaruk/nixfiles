{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  options = {
    batat.programs.enable = lib.mkEnableOption "enables basic programs";
  };

  config = lib.mkIf config.batat.programs.enable {

    environment.systemPackages = with pkgs; [
      anki-bin

      # deprecated due to electron 35 dependency
      # affine # mira alternative; collaborative whiteboard & markdown database

      telegram-desktop

      # notebook
      nb

      lorien # minimalistic infinite canvas

      vlc

      #     ghostty # terminal emulator

      folo
      #openssl_legacy

      # Tag Studio
      # UI for managing files marked by tags
      # written in python by youtuber, weights 2GB
      # inputs.tagstudio.packages.${pkgs.stdenv.hostPlatform.system}.tagstudio
    ];

    programs.firefox.enable = true;
  };
}
