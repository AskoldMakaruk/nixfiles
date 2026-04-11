{
  lib,
  config,
  inputs,
  ...
}:
let
  cfg = config.batat.fluent-bit;
  inherit (inputs) mysecrets;
in
{
  options.batat.fluent-bit = {
    enable = lib.mkEnableOption "Enable Fluent Bit log forwarding";
    openObserveHost = lib.mkOption {
      type = lib.types.str;
      default = "localhost";
      description = "OpenObserve host";
    };
    openObservePort = lib.mkOption {
      type = lib.types.int;
      default = 5800;
      description = "OpenObserve port";
    };
    openObserveUri = lib.mkOption {
      type = lib.types.str;
      default = "/api/default/docker/_json";
      description = "OpenObserve ingestion URI";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.fluentBitCredentials = {
      file = mysecrets + "/fluent-bit.age";
    };

    services.fluent-bit = {
      enable = true;
      settings = {
        service = {
          grace = 30;
        };
        pipeline = {
          inputs = [
            {
              name = "systemd";
              systemd_filter = "_SYSTEMD_UNIT=docker.service";
            }
          ];
          filters = [
            {
              name = "grep";
              match = "*";
              exclude = "CONTAINER_NAME dohly-observe";
            }
          ];
          outputs = [
            {
              name = "http";
              match = "*";
              host = cfg.openObserveHost;
              port = cfg.openObservePort;
              uri = cfg.openObserveUri;
              tls = "off";
              format = "json";
              json_date_key = "_timestamp";
              json_date_format = "iso8601";
              http_user = "\${OPENOBSERVE_USER}";
              http_passwd = "\${OPENOBSERVE_PASSWORD}";
              compress = "gzip";
            }
          ];
        };
      };
    };

    systemd.services.fluent-bit.serviceConfig.EnvironmentFile =
      config.age.secrets.fluentBitCredentials.path;
  };
}
