{ ... }:
{
  services.nginx = {
    enable = true;
    virtualHosts."_" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 80;
        }
      ];
      locations."/" = {
        proxyPass = "https://articles.dev.fora.lan/";

        extraConfig = ''
          proxy_set_header Host articles.dev.fora.lan;
        '';
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
  ];
}
