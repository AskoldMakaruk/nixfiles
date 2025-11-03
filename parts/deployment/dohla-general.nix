{
  lib,
  config,
  pkgs,
  ...
}:
let
  mkDockerNetwork = import ./docker-network.nix;
in
{
  config = lib.mkIf config.batat.dohla.enable (
    let
      projectPath = "/home/askold/src/DohlaRusnya";

      generalRoot = "docker-compose-dohly-general-root.target";
      generalNetwork = "docker-network-dohly-general";
      generalNetworkService = "${generalNetwork}.service";
    in
    {
      # GENERAL
      systemd.services."dohly-api-build-restarter" =
        let
          gitDir = "/home/askold/repos/dohly-back.git";
          configFile = pkgs.writeShellApplication {
            name = "exec.sh";
            text = ''
              find ${gitDir}/* | ${pkgs.entr}/bin/entr -n -s '${pkgs.git}/bin/git --work-tree ${projectPath} pull local master && ${pkgs.systemd}/bin/systemctl restart docker-build-dohly-api-test.service'
            '';
          };
        in
        {
          description = "Restarts build on code change";
          serviceConfig = {
            Type = "simple";
            Restart = "always";
            ExecStart = "${configFile}/bin/exec.sh";
          };
          wantedBy = [ "multi-user.target" ];
        };

      # DATABASE
      virtualisation.oci-containers.containers."dohly-database" = {
        image = "dohly-database";
        environmentFiles = [
          "/run/agenix/postgres"
        ];
        volumes = [
          "dohly-db-volume:/var/lib/postgresql/data:rw"
        ];
        ports = [
          "0.0.0.0:5432:5432/tcp"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=db"
          "--network=dohly-general"
        ];
      };

      systemd.services."docker-dohly-database" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "always";
          RestartMaxDelaySec = lib.mkOverride 90 "1m";
          RestartSec = lib.mkOverride 90 "100ms";
          RestartSteps = lib.mkOverride 90 9;
        };

        after = [
          "docker-build-dohly-database.service"
          generalNetworkService
        ];

        requires = [
          "docker-build-dohly-api-test.service"
          generalNetworkService
        ];

        partOf = [ generalRoot ];
        wantedBy = [ generalRoot ];
      };

      systemd.services."docker-build-dohly-database" = {
        path = [
          pkgs.docker
          pkgs.nix
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          TimeOutSec = 300;
        };
        script = ''
          cd /home/askold/src/DohlaRusnya/src/deploy/docker
          docker build -t dohly-database -f db.dockerfile .
        '';

        partOf = [ generalRoot ];
        wantedBy = [ generalRoot ];
      };
      # OPENOBSERVE
      virtualisation.oci-containers.containers."dohly-observe" = {
        image = "public.ecr.aws/zinclabs/openobserve:latest";
        environmentFiles = [
          #-e ZO_DATA_DIR="/data"
          "/run/agenix/openobserve"
        ];
        volumes = [
          "dohly-observe-volume:/data:rw"
        ];
        ports = [
          "0.0.0.0:5800:5080/tcp"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=openobserve"
          "--network=dohly-general"
        ];
      };

      systemd.services."docker-dohly-observe" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "always";
          RestartMaxDelaySec = lib.mkOverride 90 "1m";
          RestartSec = lib.mkOverride 90 "100ms";
          RestartSteps = lib.mkOverride 90 9;
        };
        after = [ generalNetworkService ];
        requires = [ generalNetworkService ];
        partOf = [ generalRoot ];
        wantedBy = [ generalRoot ];
      };

      # VOLUME
      systemd.services."docker-volume-dohly-observe-volume" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect dohly-observe-volume || docker volume create dohly-observe-volume
        '';
        partOf = [ generalRoot ];
        wantedBy = [ generalRoot ];
      };

      systemd.services."docker-volume-dohly-db-volume" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect dohly-db-volume || docker volume create dohly-db-volume
        '';
        partOf = [ generalRoot ];
        wantedBy = [ generalRoot ];
      };

      # Networks
      systemd.services."${generalNetwork}" = mkDockerNetwork {
        inherit pkgs;
        networkName = "dohly-general";
        root = generalRoot;
      };

      systemd.targets."${generalRoot}" = {
        unitConfig = {
          Description = "Root target for dohly project general";
        };
        wantedBy = [ "multi-user.target" ];
      };
    }
  );
}
