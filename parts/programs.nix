{
  config,
  lib,
  pkgs,
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

      lorien # minimalistic infinite canvas

      vlc

      #     ghostty # terminal emulator

      follow
      #openssl_legacy
    ];

    programs.firefox.enable = true;
  };
}
