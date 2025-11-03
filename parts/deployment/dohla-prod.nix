{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  mkDockerNetwork = import ./docker-network.nix;
  mkDockerBuild = import ./docker-build.nix;
in
{
  config = lib.mkIf config.batat.dohla.enable (
    let
      projectPath = "/home/askold/src/DohlaRusnya";
      apiProjectPath = "${projectPath}/src/server/DohlaRusnya3.4.and.5/DohlaRusnya.Api";

      prodRoot = "docker-dohly-prod-root.target";
      prodApiPath = "${apiProjectPath}/default.nix";
      prodNetwork = "docker-network-dohly-prod";
      prodNetworkService = "${prodNetwork}.service";

      generalNetwork = "docker-network-dohly-general";
      generalNetworkService = "${generalNetwork}.service";
    in
    {
      #PROD

      # API
      virtualisation.oci-containers.containers."dohly-api-prod" = {
        image = "dohly-api-prod";
        environmentFiles = [
          "/run/agenix/api-prod"
        ];
        dependsOn = [ "dohly-database" ];
        ports = [
          "0.0.0.0:6100:5000/tcp"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=dohly-api-prod"
          "--network=dohly-prod"
          "--network=dohly-general"
        ];
      };

      systemd.services."docker-dohly-api-prod" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "always";
          RestartMaxDelaySec = lib.mkOverride 90 "1m";
          RestartSec = lib.mkOverride 90 "100ms";
          RestartSteps = lib.mkOverride 90 9;
        };

        after = [
          "docker-build-dohly-api-prod.service"
          prodNetworkService
          generalNetworkService
        ];
        requires = [
          "docker-build-dohly-api-prod.service"
          prodNetworkService
          generalNetworkService
        ];

        partOf = [ prodRoot ];
        wantedBy = [ prodRoot ];
      };

      systemd.services."docker-build-dohly-api-prod" = mkDockerBuild {
        inherit pkgs;
        projectPath = prodApiPath;
        packageName = "apiImage";
        envName = "prod";
        root = prodRoot;
        port = "6100";
      };

      # FRONT
      virtualisation.oci-containers.containers."dohly-front-prod" = {
        image = "dohly-front-prod";
        environmentFiles = [
          # "/run/agenix/front-prod"
        ];
        dependsOn = [ "dohly-api-prod" ];
        ports = [
          "0.0.0.0:6200:3000/tcp"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=dohly-front-prod"
          "--network=dohly-prod"
          "--network=dohly-general"
        ];
      };

      systemd.services."docker-dohly-front-prod" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "always";
          RestartMaxDelaySec = lib.mkOverride 90 "1m";
          RestartSec = lib.mkOverride 90 "100ms";
          RestartSteps = lib.mkOverride 90 9;
        };

        after = [
          "docker-build-dohly-front-prod.service"
          prodNetworkService
          generalNetworkService
        ];

        requires = [
          "docker-build-dohly-front-prod.service"
          prodNetworkService
          generalNetworkService
        ];

        partOf = [ prodRoot ];
        wantedBy = [ prodRoot ];
      };

      systemd.services."docker-build-dohly-front-prod" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          TimeOutSec = 300;
        };
        script = ''
          cd /home/askold/src/tic-tac-toe/tictactoe/
          docker build -t dohly-front-test -f Dockerfile .
        '';
        partOf = [ prodRoot ];
        wantedBy = [ prodRoot ];
      };

      # Networks
      systemd.services."${prodNetwork}" = mkDockerNetwork {
        inherit pkgs;
        networkName = "dohly-prod";
        root = prodRoot;
      };

      systemd.targets."${prodRoot}" = {
        unitConfig = {
          Description = "Root target for dohly project prod";
        };
        wantedBy = [ "multi-user.target" ];
      };

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
    }
  );
}
