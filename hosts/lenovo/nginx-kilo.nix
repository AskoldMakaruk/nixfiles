{ config, lib, pkgs, ... }:
let
  lanRanges = [
    "10.0.0.0/8"
    "172.16.0.0/12"
    "192.168.0.0/16"
    "127.0.0.0/8"
  ];
  allowRules = lib.concatMapStringsSep "\n" (ip: "allow ${ip};") lanRanges;
in
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts."_" = {
      listen = [
        { addr = "0.0.0.0"; port = 80; }
      ];
      locations."/" = {
        proxyPass = "http://127.0.0.1:4096";
        proxyWebsockets = true;
      };
      extraConfig = ''
        ${allowRules}
        deny all;
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
}
