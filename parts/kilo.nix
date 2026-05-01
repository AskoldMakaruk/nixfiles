{ config, lib, ... }:

{
  options = {
    batat.kilo.enable = lib.mkEnableOption "enables Kilo dotfiles (skills, config)";
  };

  config = lib.mkIf config.batat.kilo.enable {
    home-manager.users.askold = import ./kilo-hm.nix;
  };
}
