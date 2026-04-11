{
  config,
  pkgs,
  inputs,
  ...
}:
let
  inherit (inputs) mysecrets;
in
{
  services.nextcloud = {
    enable = true;
    hostName = "nextcloud.askold.dev";
    package = pkgs.nextcloud32;
    datadir = "/data/nextcloud";
    database.createLocally = true;
    configureRedis = true;
    https = true;
    maxUploadSize = "1G";
    autoUpdateApps.enable = true;
    appstoreEnable = true;
    settings = {
      default_phone_region = "UA";
      maintenance_window_start = 2;
      overwriteprotocol = "https";
      log_type = "file";
      # trust timba-1 as reverse proxy (entire tailscale subnet)
      trusted_proxies = [ "100.64.0.0/10" ];
      allow_local_remote_servers = true;
    };
    config = {
      dbtype = "pgsql";
      dbname = "nextcloud";
      dbuser = "nextcloud";
      adminuser = "admin";
      adminpassFile = config.age.secrets.nextcloudPass.path;
    };
    phpOptions = {
      output_buffering = "0";
      "opcache.interned_strings_buffer" = "12";
    };
  };

  services.postgresqlBackup = {
    enable = true;
    location = "/data/backups/postgresql";
    databases = [ "nextcloud" ];
    startAt = "*-*-* 23:15:00";
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers.collabora = {
      image = "collabora/code:25.04.8.1.1";
      ports = [ "9980:9980" ];
      environment = {
        domain = "office.askold.dev";
        extra_params = "--o:ssl.enable=false --o:ssl.termination=true";
      };
      extraOptions = [
        "--cap-add"
        "MKNOD"
      ];
    };
    containers.whiteboard = {
      image = "nextcloud/aio-whiteboard:latest";
      environment = {
        NEXTCLOUD_URL = "https://nextcloud.askold.dev";
        REDIS_HOST = "127.0.0.1";
      };
      environmentFiles = [ config.age.secrets.whiteboardSecret.path ];
      extraOptions = [ "--network=host" ];
    };
  };

  services.redis.servers.nextcloud = {
    bind = "127.0.0.1";
    port = 6379;
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."nextcloud.askold.dev" = {
      extraConfig = ''
        add_header X-XSS-Protection "1; mode=block" always;
      '';
    };

    virtualHosts."office.askold.dev" = {
      locations = {
        "^~ /browser" = {
          proxyPass = "http://127.0.0.1:9980";
          proxyWebsockets = true;
          extraConfig = "proxy_set_header Host $host;";
        };
        "^~ /hosting/discovery" = {
          proxyPass = "http://127.0.0.1:9980";
          proxyWebsockets = true;
          extraConfig = "proxy_set_header Host $host;";
        };
        "^~ /hosting/capabilities" = {
          proxyPass = "http://127.0.0.1:9980";
          proxyWebsockets = true;
          extraConfig = "proxy_set_header Host $host;";
        };
        "~ ^/cool/(.*)/ws$" = {
          proxyPass = "http://127.0.0.1:9980";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "Upgrade";
            proxy_set_header Host $host;
            proxy_read_timeout 36000s;
          '';
        };
        "~ ^/(c|l)ool" = {
          proxyPass = "http://127.0.0.1:9980";
          proxyWebsockets = true;
          extraConfig = "proxy_set_header Host $host;";
        };
        "^~ /cool/adminws" = {
          proxyPass = "http://127.0.0.1:9980";
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

    virtualHosts."whiteboard.askold.dev" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:3002";
        proxyWebsockets = true;
      };
    };
  };

  # After deploy, run once:
  #   nextcloud-occ config:app:set whiteboard collabBackendUrl --value "https://whiteboard.askold.dev"
  #   nextcloud-occ config:app:set richdocuments public_wopi_url --value "https://office.askold.dev"
  systemd.services.nextcloud-whiteboard-config = {
    description = "Configure Nextcloud whiteboard JWT secret";
    after = [ "nextcloud-setup.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "nextcloud";
      RemainAfterExit = true;
      Environment = "PATH=/run/current-system/sw/bin";
    };
    script = ''
      secret=$(grep JWT_SECRET_KEY ${config.age.secrets.whiteboardSecret.path} | cut -d= -f2)
      nextcloud-occ config:app:set whiteboard jwt_secret_key --value "$secret"
      nextcloud-occ config:app:set richdocuments wopi_url --value "http://127.0.0.1:9980"
    '';
  };

  age.secrets = {
    nextcloudPass = {
      file = mysecrets + "/nextcloudPass.age";
      owner = "nextcloud";
    };
    whiteboardSecret = {
      file = mysecrets + "/whiteboardSecret.age";
    };
  };
}
