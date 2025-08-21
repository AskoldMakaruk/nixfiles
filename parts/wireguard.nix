{ config, pkgs, ... }:
let
  wg_pub = "kRwY/ICZEV/9rcpjKWSRFnaWf9TWbeNj2icXpKOF820=";
in
{

  networking.firewall = {
    allowedUDPPorts = [ 51820 ];
    allowedTCPPorts = [ 5173 ];
  };
  networking.wireguard.enable = true;
  networking.wireguard.interfaces = {
    wg0 = {
      # ips = [ per host basis ];
      listenPort = 51820;

      privateKeyFile = config.age.secrets.wg_key.path;
      allowedIPsAsRoutes = true;
      postSetup = ''
        ENDPOINT=$(cat ${config.age.secrets.wg_endpoint.path})
        ${pkgs.wireguard-tools}/bin/wg set wg0 peer "${wg_pub}" endpoint "$ENDPOINT"
      '';

      postShutdown = ''
        ${pkgs.wireguard-tools}/bin/wg set wg0 peer "${wg_pub}" endpoint ""
      '';

      peers = [
        {
          publicKey = wg_pub;
          allowedIPs = [ "10.5.5.0/24" ];
          #endpoint = loading public ip from secret insted via postSetup;
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
