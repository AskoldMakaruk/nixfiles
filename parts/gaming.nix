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
    batat.gaming.enable = lib.mkEnableOption "enables steam";
  };

  config = lib.mkIf config.batat.gaming.enable {

    programs.steam = {
      enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    };

  };
}
