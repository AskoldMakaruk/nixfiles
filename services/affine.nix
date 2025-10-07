# nix run github:aksiksi/compose2nix -- -build -project=dolha -runtime docker -inputs bot-db.yml bot-db.prod.yml

{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

let
  inherit (inputs) mysecrets;
in
{
  options = {
    batat.affine.enable = lib.mkEnableOption "enables Affine service";
  };

  # HOW TO UPDATE affine
  # stop service
  # docker pull "ghcr.io/toeverything/affine:stable"
  # start service
  #
  config = lib.mkIf config.batat.affine.enable {

    # Secrets
    age.secrets = {
      affine-server.file = mysecrets + "/affine/server.age";
      affine-postgres.file = mysecrets + "/affine/postgres.age";
    };

    # Auto-generated using compose2nix v0.3.2-pre.
    # Runtime
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
    };
    virtualisation.oci-containers.backend = "docker";

    # Containers
    virtualisation.oci-containers.containers."affine_migration_job" = {
      image = "ghcr.io/toeverything/affine:stable";
      environmentFiles = [
        "/run/agenix/affine-server"
      ];
      volumes = [
        "/home/askold/.affine/self-host/config:/root/.affine/config:rw"
        "/home/askold/.affine/self-host/storage:/root/.affine/storage:rw"
      ];
      cmd = [
        "sh"
        "-c"
        "node ./scripts/self-host-predeploy.js"
      ];
      dependsOn = [
        "affine_postgres"
        "affine_redis"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=affine_migration"
        "--network=affine_default"
      ];
    };
    systemd.services."docker-affine_migration_job" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "no";
      };
      after = [
        "docker-network-affine_default.service"
      ];
      requires = [
        "docker-network-affine_default.service"
      ];
      partOf = [
        "docker-compose-affine-root.target"
      ];
      wantedBy = [
        "docker-compose-affine-root.target"
      ];
    };
    virtualisation.oci-containers.containers."affine_postgres" = {
      image = "pgvector/pgvector:pg16";
      environmentFiles = [
        "/run/agenix/affine-postgres"
      ];
      volumes = [
        "/home/askold/.affine/self-host/postgres/pgdata:/var/lib/postgresql/data:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--health-cmd=[\"pg_isready\", \"-U\", \"affine\", \"-d\", \"affine\"]"
        "--health-interval=10s"
        "--health-retries=5"
        "--health-timeout=5s"
        "--network-alias=postgres"
        "--network=affine_default"
      ];
    };
    systemd.services."docker-affine_postgres" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
        RestartMaxDelaySec = lib.mkOverride 90 "1m";
        RestartSec = lib.mkOverride 90 "100ms";
        RestartSteps = lib.mkOverride 90 9;
      };
      after = [
        "docker-network-affine_default.service"
      ];
      requires = [
        "docker-network-affine_default.service"
      ];
      partOf = [
        "docker-compose-affine-root.target"
      ];
      wantedBy = [
        "docker-compose-affine-root.target"
      ];
    };
    virtualisation.oci-containers.containers."affine_redis" = {
      image = "redis";
      log-driver = "journald";
      extraOptions = [
        "--health-cmd=[\"redis-cli\", \"--raw\", \"incr\", \"ping\"]"
        "--health-interval=10s"
        "--health-retries=5"
        "--health-timeout=5s"
        "--network-alias=redis"
        "--network=affine_default"
      ];
    };
    systemd.services."docker-affine_redis" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
        RestartMaxDelaySec = lib.mkOverride 90 "1m";
        RestartSec = lib.mkOverride 90 "100ms";
        RestartSteps = lib.mkOverride 90 9;
      };
      after = [
        "docker-network-affine_default.service"
      ];
      requires = [
        "docker-network-affine_default.service"
      ];
      partOf = [
        "docker-compose-affine-root.target"
      ];
      wantedBy = [
        "docker-compose-affine-root.target"
      ];
    };
    virtualisation.oci-containers.containers."affine_server" = {
      image = "ghcr.io/toeverything/affine:stable";
      environmentFiles = [
        "/run/agenix/affine-server"
      ];
      volumes = [
        "/home/askold/.affine/self-host/config:/root/.affine/config:rw"
        "/home/askold/.affine/self-host/storage:/root/.affine/storage:rw"
      ];
      ports = [
        "5666:3010/tcp"
      ];
      dependsOn = [
        "affine_migration_job"
        "affine_postgres"
        "affine_redis"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=affine"
        "--network=affine_default"
      ];
    };
    systemd.services."docker-affine_server" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
        RestartMaxDelaySec = lib.mkOverride 90 "1m";
        RestartSec = lib.mkOverride 90 "100ms";
        RestartSteps = lib.mkOverride 90 9;
      };
      after = [
        "docker-network-affine_default.service"
      ];
      requires = [
        "docker-network-affine_default.service"
      ];
      partOf = [
        "docker-compose-affine-root.target"
      ];
      wantedBy = [
        "docker-compose-affine-root.target"
      ];
    };

    # Networks
    systemd.services."docker-network-affine_default" = {
      path = [ pkgs.docker ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "docker network rm -f affine_default";
      };
      script = ''
        docker network inspect affine_default || docker network create affine_default
      '';
      partOf = [ "docker-compose-affine-root.target" ];
      wantedBy = [ "docker-compose-affine-root.target" ];
    };

    # Root service
    # When started, this will automatically create all resources and start
    # the containers. When stopped, this will teardown all resources.
    systemd.targets."docker-compose-affine-root" = {
      unitConfig = {
        Description = "Root target generated by compose2nix.";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
