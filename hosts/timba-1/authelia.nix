{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf;
in
{
  services.redis = {
    enable = true;
    port = 6379;
    bind = "127.0.0.1";
  };

  services.authelia.instances.main = {
    enable = true;

    secrets = {
      jwtSecretFile = config.age.secrets.autheliaJwtSecret.path;
      storageEncryptionKeyFile = config.age.secrets.autheliaStorageEncryptionKey.path;
      sessionSecretFile = config.age.secrets.autheliaSessionSecret.path;
    };

    settings = {
      theme = "dark";
      default_2fa_method = "totp";

      server.address = "tcp://127.0.0.1:9091/";

      log.level = "info";

      authentication_backend.file.path = config.age.secrets.autheliaUsers.path;

      access_control = {
        default_policy = "deny";
        rules = [
          {
            domain = "git.askold.dev";
            policy = "one_factor";
          }
          {
            domain = "auth.askold.dev";
            policy = "bypass";
          }
          {
            domain = "logs.dead-idiots.rip";
            policy = "one_factor";
          }
          {
            domain = "dead-idiots.rip";
            policy = "bypass";
          }
          {
            domain = "grocy.askold.dev";
            policy = "one_factor";
          }
          {
            domain = "manga.askold.dev";
            policy = "one_factor";
          }
        ];
      };

      session = {
        name = "authelia_session";
        same_site = "lax";
        inactivity = "5m";
        expiration = "24h";
        remember_me = "1M";
        redis = {
          host = "127.0.0.1";
          port = 6379;
        };
        cookies = [
          {
            domain = "askold.dev";
            authelia_url = "https://auth.askold.dev";
          }
          {
            domain = "dead-idiots.rip";
            authelia_url = "https://auth.dead-idiots.rip";
          }
        ];
      };

      storage.local.path = "/var/lib/authelia-main/db.sqlite3";

      notifier.filesystem.filename = "/var/lib/authelia-main/notifications.yml";

      totp.issuer = "askold.dev";

      ntp = {
        address = "time.cloudflare.com";
        version = 4;
        max_desync = "3s";
        disable_startup_check = false;
        disable_failure = false;
      };
    };
  };
}
