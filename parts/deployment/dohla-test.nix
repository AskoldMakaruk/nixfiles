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
  mkNotify = import ./notify.nix;
  telegramNotify = mkNotify { inherit pkgs; };
  projectPath = "/home/askold/src/DohlaRusnya";
  apiProjectPath = "${projectPath}/src/server/DohlaRusnya3.4.and.5/DohlaRusnya.Api";

  testRoot = "docker-dohly-test-root.target";
  testApiPath = "${apiProjectPath}/default.nix";
  testNetwork = "docker-network-dohly-test";
  testNetworkService = "${testNetwork}.service";
  testProxyPath = "${projectPath}/src/server/DohlaRusnya3.4.and.5/Proxy/default.nix";

  generalNetwork = "docker-network-dohly-general";
  generalNetworkService = "${generalNetwork}.service";
in
{
  config = lib.mkMerge [

    # TEST
    {
      # Networks
      systemd.services."${testNetwork}" = mkDockerNetwork {
        inherit pkgs;
        networkName = "dohly-test";
        root = testRoot;
      };

      systemd.targets."${testRoot}" = {
        unitConfig = {
          Description = "Root target for dohly project test";
        };
        wantedBy = [ "multi-user.target" ];
      };
    }

    (lib.mkIf config.batat.dohla.test.api.enable ({
      # PROXY
      # virtualisation.oci-containers.containers."dohly-proxy-test" = {
      #   image = "dohly-proxy-test";
      #   environmentFiles = [
      #     "/run/agenix/api-test"
      #     #"/home/askold/src/DohlaRusnya/src/server/DohlaRusnya3.4.and.5/DohlaRusnya.Api/.env"
      #   ];
      #   # dependsOn = [ "dohly-database" ];
      #   ports = [
      #     "0.0.0.0:7000:5000/tcp"
      #   ];
      #   log-driver = "journald";
      #   extraOptions = [
      #     "--network-alias=dohly-proxy-test"
      #     "--network=dohly-test"
      #     "--network=dohly-general"
      #   ];
      # };
      #
      # systemd.services."docker-dohly-proxy-test" = {
      #   serviceConfig = {
      #     Restart = lib.mkOverride 90 "always";
      #     RestartMaxDelaySec = lib.mkOverride 90 "1m";
      #     RestartSec = lib.mkOverride 90 "100ms";
      #     RestartSteps = lib.mkOverride 90 9;
      #   };
      #
      #   after = [
      #     "docker-build-dohly-proxy-test.service"
      #     testNetworkService
      #     generalNetworkService
      #   ];
      #
      #   requires = [
      #     "docker-build-dohly-proxy-test.service"
      #     testNetworkService
      #     generalNetworkService
      #   ];
      #
      #   partOf = [ testRoot ];
      #   wantedBy = [ testRoot ];
      # };
      #
      # systemd.services."docker-build-dohly-proxy-test" = mkDockerBuild {
      #   inherit pkgs;
      #   projectPath = testProxyPath;
      #   packageName = "proxy";
      #   envName = "test";
      #   root = testRoot;
      #   port = "7100";
      # };
      #
      # API
      virtualisation.oci-containers.containers."dohly-api-test" = {
        image = "dohly-api-test";
        environmentFiles = [
          "/run/agenix/api"
          # "/home/askold/src/DohlaRusnya/src/server/DohlaRusnya3.4.and.5/DohlaRusnya.Api/.env"
        ];
        dependsOn = [ "dohly-database" ];
        ports = [
          "0.0.0.0:7100:5000/tcp"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=dohly-api-test"
          "--network=dohly-test"
          "--network=dohly-general"
        ];
      };

      systemd.services."docker-dohly-api-test" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "always";
          RestartMaxDelaySec = lib.mkOverride 90 "1m";
          RestartSec = lib.mkOverride 90 "100ms";
          RestartSteps = lib.mkOverride 90 9;
        };

        after = [
          # "docker-build-dohly-api-test.service"
          testNetworkService
          generalNetworkService
        ];

        requires = [
          # "docker-build-dohly-api-test.service"
          testNetworkService
          generalNetworkService
        ];

        partOf = [ testRoot ];
        wantedBy = [ testRoot ];
      };

      # systemd.services."docker-build-dohly-api-test" = mkDockerBuild {
      #   inherit pkgs;
      #   projectPath = testApiPath;
      #   packageName = "apiImage";
      #   envName = "test";
      #   root = testRoot;
      #   port = "7100";
      # };

    }))

    # FRONT
    (lib.mkIf config.batat.dohla.test.front.enable ({
      virtualisation.oci-containers.containers."dohly-front-test" = {
        image = "dohly-front-test:latest";
        environmentFiles = [
          "/run/agenix/front-test"
        ];
        dependsOn = [
          #  "dohly-api-test"
        ];
        ports = [
          "0.0.0.0:7200:3000/tcp"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=dohly-front-test"
          "--network=dohly-test"
          "--network=dohly-general"
        ];
      };

      systemd.services."docker-dohly-front-test" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "always";
          RestartMaxDelaySec = lib.mkOverride 90 "1m";
          RestartSec = lib.mkOverride 90 "100ms";
          RestartSteps = lib.mkOverride 90 9;
        };

        after = [
          "docker-build-dohly-front-test.service"
          testNetworkService
          generalNetworkService
        ];

        requires = [
          "docker-build-dohly-front-test.service"
          testNetworkService
          generalNetworkService
        ];

        partOf = [ testRoot ];
        wantedBy = [ testRoot ];
      };

      systemd.services."docker-build-dohly-front-test" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          TimeOutSec = 300;
        };
        script = ''
          cd /home/askold/src/tic-tac-toe/tictactoe/
          # docker build -t dohly-front-test:latest -f dev.dockerfile .
          docker build -t dohly-front-test:latest -f Dockerfile .
        '';
        partOf = [ testRoot ];
        wantedBy = [ testRoot ];
      };

      systemd.services."dohly-front-git-pull" = {
        description = "Pull dohly frontend repo and rebuild+restart on changes";
        path = [
          pkgs.git
          pkgs.openssh
          pkgs.curl
        ];
        serviceConfig = {
          Type = "oneshot";
          User = "askold";
          EnvironmentFile = "/run/agenix/telegram-bot";
        };
        script = ''
          trap '${telegramNotify} "[dohly-front] git-pull service failed"' ERR
          set -e

          cd /home/askold/src/tic-tac-toe/tictactoe/

          branch=$(git rev-parse --abbrev-ref HEAD)
          git fetch origin "$branch"

          local=$(git rev-parse HEAD)
          remote=$(git rev-parse "origin/$branch")

          if [ "$local" != "$remote" ]; then
            changes=$(git log --oneline "$local".."origin/$branch")
            ${telegramNotify} "[dohly-front] new commits, rebuilding:
            $changes"
            git merge --ff-only
            if /run/wrappers/bin/sudo /run/current-system/sw/bin/systemctl restart docker-build-dohly-front-test.service && \
               /run/wrappers/bin/sudo /run/current-system/sw/bin/systemctl restart docker-dohly-front-test.service; then
              ${telegramNotify} "[dohly-front] rebuild and restart done"
            else
              ${telegramNotify} "[dohly-front] restart failed after pull"
              exit 1
            fi
          fi
        '';
      };

      systemd.timers."dohly-front-git-pull" = {
        description = "Check dohly frontend git repo every minute";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "1min";
          OnUnitActiveSec = "1min";
          Unit = "dohly-front-git-pull.service";
        };
      };

      security.sudo.extraRules = [
        {
          users = [ "askold" ];
          commands = [
            {
              command = "/run/current-system/sw/bin/systemctl restart docker-build-dohly-front-test.service";
              options = [ "NOPASSWD" ];
            }
            {
              command = "/run/current-system/sw/bin/systemctl restart docker-dohly-front-test.service";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];

    }))
  ];
}
