{
  lib,
  config,
  inputs,
  ...
}:
let
  cfg = config.batat.acme;
  inherit (inputs) mysecrets;
in
{

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."logs.dead-idiots.rip" = {
      forceSSL = true;
      useACMEHost = "dead-idiots.rip";
      locations = {
        "/" = {
          proxyPass = "http://100.118.231.37:5800";
        };
      };
    };

    virtualHosts."dead-idiots.rip" = {
      forceSSL = true;
      useACMEHost = "dead-idiots.rip";
      locations = {
        "/" = {
          proxyPass = "http://100.118.231.37:7200";
          proxyWebsockets = true;
        };
        "/api" = {
          proxyPass = "http://100.118.231.37:7100";
          proxyWebsockets = true;
        };
        "/logs" = {
          proxyPass = "http://100.118.231.37:5800";
          proxyWebsockets = true;
        };
      };
    };

    virtualHosts."nextcloud.askold.dev" = {
      forceSSL = true;
      useACMEHost = "askold.dev";
      locations = {
        "/" = {
          proxyPass = "http://100.118.231.37";
        };
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "Cascade2000@proton.me";
      dnsProvider = "cloudflare";
      credentialsFile = config.age.secrets.acmeCredentials.path;
    };

    certs."askold.dev" = {
      extraDomainNames = [
        "*.askold.dev"
      ];
    };
    certs."dead-idiots.rip" = {
      extraDomainNames = [
        "*.dead-idiots.rip"
      ];
    };
  };

  users.users.nginx.extraGroups = [ "acme" ];

  age.secrets.acmeCredentials.file = mysecrets + "/acme.age";
}
