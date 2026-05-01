{
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (inputs) mysecrets;

  autheliaLocation = {
    extraConfig = ''
      internal;
      proxy_pass http://127.0.0.1:9091;
      proxy_pass_request_body off;
      proxy_set_header Content-Length "";
      proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
      proxy_set_header X-Forwarded-Method $request_method;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-Host $http_host;
      proxy_set_header X-Forwarded-Uri $request_uri;
    '';
  };

  withAuth = authDomain: extraConfig: ''
    auth_request /authelia/api/verify;
    error_page 401 =302 https://${authDomain}/?rd=$scheme://$http_host$request_uri;
    ${extraConfig}
  '';
in
{

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    # Authelia portal — users log in here
    virtualHosts."auth.askold.dev" = {
      forceSSL = true;
      useACMEHost = "askold.dev";
      locations."/" = {
        proxyPass = "http://127.0.0.1:9091";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };
    };

    virtualHosts."auth.dead-idiots.rip" = {
      forceSSL = true;
      useACMEHost = "dead-idiots.rip";
      locations."/" = {
        proxyPass = "http://127.0.0.1:9091";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };
    };

    # Protected: requires authelia auth (one_factor)
    virtualHosts."logs.dead-idiots.rip" = {
      forceSSL = true;
      useACMEHost = "dead-idiots.rip";
      locations = {
        "/authelia" = autheliaLocation;
        "/" = {
          proxyPass = "http://100.118.231.37:5800";
          extraConfig = withAuth "auth.dead-idiots.rip" "";
        };
      };
    };

    virtualHosts."dead-idiots.rip" = {
      forceSSL = true;
      useACMEHost = "dead-idiots.rip";
      locations = {
        "/authelia" = autheliaLocation;
        "/" = {
          proxyPass = "http://100.118.231.37:7200";
          proxyWebsockets = true;
          extraConfig = withAuth "auth.dead-idiots.rip" "";
        };
        "/api" = {
          proxyPass = "http://100.118.231.37:7100";
          proxyWebsockets = true;
          extraConfig = withAuth "auth.dead-idiots.rip" "";
        };
        "/logs" = {
          proxyPass = "http://100.118.231.37:5800";
          proxyWebsockets = true;
          extraConfig = withAuth "auth.dead-idiots.rip" "";
        };
      };
    };

    virtualHosts."grocy.askold.dev" = {
      forceSSL = true;
      useACMEHost = "askold.dev";
      locations = {
        "/authelia" = autheliaLocation;
        "/" = {
          proxyPass = "http://100.118.231.37";
          proxyWebsockets = true;
          extraConfig = withAuth "auth.askold.dev" "";
        };
      };
    };

    # Not protected (services have their own auth or need direct access)
    virtualHosts."nextcloud.askold.dev" = {
      forceSSL = true;
      useACMEHost = "askold.dev";
      locations."/" = {
        proxyPass = "http://100.118.231.37";
        proxyWebsockets = true;
      };
    };

    virtualHosts."office.askold.dev" = {
      forceSSL = true;
      useACMEHost = "askold.dev";
      locations = {
        "^~ /browser" = {
          proxyPass = "http://100.118.231.37:9980";
          proxyWebsockets = true;
          extraConfig = "proxy_set_header Host $host;";
        };
        "^~ /hosting/discovery" = {
          proxyPass = "http://100.118.231.37:9980";
          proxyWebsockets = true;
          extraConfig = "proxy_set_header Host $host;";
        };
        "^~ /hosting/capabilities" = {
          proxyPass = "http://100.118.231.37:9980";
          proxyWebsockets = true;
          extraConfig = "proxy_set_header Host $host;";
        };
        "~ ^/cool/(.*)/ws$" = {
          proxyPass = "http://100.118.231.37:9980";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "Upgrade";
            proxy_set_header Host $host;
            proxy_read_timeout 36000s;
          '';
        };
        "~ ^/(c|l)ool" = {
          proxyPass = "http://100.118.231.37:9980";
          proxyWebsockets = true;
          extraConfig = "proxy_set_header Host $host;";
        };
        "^~ /cool/adminws" = {
          proxyPass = "http://100.118.231.37:9980";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "Upgrade";
            proxy_set_header Host $host;
            proxy_read_timeout 36000s;
          '';
        };
      };
    };

    virtualHosts."git.askold.dev" = {
      forceSSL = true;
      useACMEHost = "askold.dev";
      locations."/" = {
        proxyPass = "http://100.118.231.37:7300";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header Host $host;
        '';
      };
    };

    virtualHosts."whiteboard.askold.dev" = {
      forceSSL = true;
      useACMEHost = "askold.dev";
      locations."/" = {
        proxyPass = "http://100.118.231.37";
        proxyWebsockets = true;
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

  # TCP stream proxy for Forgejo SSH (git.askold.dev:2222 -> timba-2:2222)
  services.nginx.streamConfig = ''
    server {
      listen 2222;
      proxy_pass 100.118.231.37:2222;
      proxy_timeout 600s;
      proxy_connect_timeout 5s;
    }
  '';

  users.users.nginx.extraGroups = [ "acme" ];

  age.secrets.acmeCredentials.file = mysecrets + "/acme.age";
}
