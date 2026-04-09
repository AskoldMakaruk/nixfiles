{
  lib,
  config,
  inputs,
  ...
}:
let
  cfg = config.batat.acme;
  inherit (inputs) mysecrets;
  locationSubmodule = lib.types.submodule {
    options = {
      location = lib.mkOption {
        type = lib.types.str;
        default = "/";
        description = "Nginx location path";
      };
      proxyPass = lib.mkOption {
        type = lib.types.str;
        description = "Backend URL to proxy to";
      };
      proxyWebsockets = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable websocket proxying";
      };
    };
  };
  domainSubmodule = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Domain name";
      };
      locations = lib.mkOption {
        type = lib.types.listOf locationSubmodule;
        description = "Proxy locations for this domain";
      };
    };
  };
in
{
  options.batat.acme = {
    enable = lib.mkEnableOption "Enable Nginx with ACME wildcard certificate";
    email = lib.mkOption {
      type = lib.types.str;
      default = "askoldmakaruk@gmail.com";
      description = "Email address to use for ACME registration";
    };
    dnsProvider = lib.mkOption {
      type = lib.types.str;
      default = "cloudflare";
      description = "DNS provider used for ACME certificate";
    };
    domains = lib.mkOption {
      type = lib.types.listOf domainSubmodule;
      default = [
        {
          name = "askold.dev";
          locations = [
            {
              location = "/";
              proxyPass = "http://100.118.231.37:7200";
            }
            {
              location = "/api";
              proxyPass = "http://100.118.231.37:7100";
            }
          ];
        }
      ];
      description = "Domains with their proxy targets";
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts = lib.listToAttrs (
        map (domain: {
          name = domain.name;
          value = {
            forceSSL = true;
            useACMEHost = domain.name;
            locations = lib.listToAttrs (
              map (loc: {
                name = loc.location;
                value = {
                  proxyPass = loc.proxyPass;
                  proxyWebsockets = loc.proxyWebsockets;
                };
              }) domain.locations
            );
          };
        }) cfg.domains
      );

    };

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = cfg.email;
        dnsProvider = cfg.dnsProvider;
        credentialsFile = config.age.secrets.acmeCredentials.path;
      };

      certs = lib.listToAttrs (
        map (domain: {
          name = domain.name;
          value = {
            extraDomainNames = [
              "*.${domain.name}"
            ];
          };
        }) cfg.domains
      );
    };

    users.users.nginx.extraGroups = [ "acme" ];

    age.secrets.acmeCredentials.file = mysecrets + "/acme.age";
  };
}
