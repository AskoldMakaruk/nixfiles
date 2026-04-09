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
    package = pkgs.nextcloud31;
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
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  age.secrets = {
    nextcloudPass = {
      file = mysecrets + "/nextcloudPass.age";
      owner = "nextcloud";
    };
  };
}
