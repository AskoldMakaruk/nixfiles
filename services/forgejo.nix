{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (inputs) mysecrets;
in
{
  options = {
    batat.forgejo.enable = lib.mkEnableOption "enables Forgejo self-hosted git service";
  };

  config = lib.mkIf config.batat.forgejo.enable {

    age.secrets = {
      forgejo-db = {
        file = mysecrets + "/forgejo/db.age";
        owner = "forgejo";
      };
      forgejo-secret-key = {
        file = mysecrets + "/forgejo/secret-key.age";
        owner = "forgejo";
      };
    };

    services.postgresql = {
      ensureDatabases = [ "forgejo" ];
      ensureUsers = [
        {
          name = "forgejo";
          ensureDBOwnership = true;
        }
      ];
      authentication = lib.mkAfter ''
        local forgejo forgejo md5
        host forgejo forgejo 127.0.0.1/32 md5
      '';
    };

    services.forgejo = {
      enable = true;
      package = pkgs.forgejo;

      database = {
        type = "postgres";
        createDatabase = false;
        passwordFile = "/run/agenix/forgejo-db";
      };

      settings = {
        server = {
          DOMAIN = "git.askold.dev";
          ROOT_URL = "https://git.askold.dev";
          HTTP_ADDR = "0.0.0.0";
          HTTP_PORT = 7300;
          PROTOCOL = "http";
          DISABLE_SSH = false;
          SSH_PORT = 2222;
          START_SSH_SERVER = true;
          SSH_LISTEN_PORT = 2222;
          SSH_DOMAIN = "git.askold.dev";
        };
        service = {
          DISABLE_REGISTRATION = false;
        };
        security = {
          SECRET_KEY = "_";
          INTERNAL_TOKEN = "_";
        };
        session = {
          COOKIE_SECURE = false;
        };
        actions = {
          ENABLED = true;
          DEFAULT_ACTIONS_URL = "https://github.com";
        };
        "repository.pull-request" = {
          WORK_IN_PROGRESS_PREFIXES = "WIP:,[WIP]";
        };
      };
    };

    systemd.services."forgejo-setup" = {
      description = "Setup forgejo directory structure and db password";
      before = [ "forgejo.service" ];
      wantedBy = [ "forgejo.service" ];
      path = [
        pkgs.sudo
        pkgs.postgresql
        pkgs.coreutils
      ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      script = ''
        mkdir -p /var/lib/forgejo/custom/conf
        chown -R forgejo:forgejo /var/lib/forgejo
        cp /run/agenix/forgejo-secret-key /var/lib/forgejo/custom/conf/secret-key
        chown forgejo:forgejo /var/lib/forgejo/custom/conf/secret-key
        PASSWORD=$(cat /run/agenix/forgejo-db)
        sudo -u postgres psql -c "ALTER USER forgejo PASSWORD '"$PASSWORD"';"
      '';
    };

    systemd.services.forgejo = {
      after = [ "forgejo-setup.service" ];
      path = [ pkgs.openssh ];
    };

    networking.firewall.allowedTCPPorts = [
      7300
      2222
    ];
  };
}
