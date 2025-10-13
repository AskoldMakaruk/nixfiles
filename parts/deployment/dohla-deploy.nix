{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  inherit (inputs) mysecrets;
in
{

  imports = [ ./nginx-test.nix ];
  options = {
    batat.dohla.enable = lib.mkEnableOption "enables deployment of dohla rusnya services";
  };

  config = lib.mkIf config.batat.dohla.enable (
    let
      testRoot = "docker-dohly-test-root.target";
      testApiPath = "/home/askold/src/DohlaRusnya/src/server/DohlaRusnya3.4.and.5/DohlaRusnya.Api/default.nix";
      testNetwork = "docker-network-dohly-test";
      testNetworkService = "${testNetwork}.service";

      prodRoot = "docker-dohly-prod-root.target";
      prodApiPath = "/home/askold/src/DohlaRusnya/src/server/DohlaRusnya3.4.and.5/DohlaRusnya.Api/default.nix";
      prodNetwork = "docker-network-dohly-prod";
      prodNetworkService = "${prodNetwork}.service";

      generalRoot = "docker-compose-dohly-general-root.target";
      generalNetwork = "docker-network-dohly-general";
      generalNetworkService = "${generalNetwork}.service";
    in
    {
      systemd.services."docker-dohly-nginx-test" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "always";
          RestartMaxDelaySec = lib.mkOverride 90 "1m";
          RestartSec = lib.mkOverride 90 "100ms";
          RestartSteps = lib.mkOverride 90 9;
        };

        after = [
          testNetworkService
          generalNetworkService
        ];

        requires = [
          testNetworkService
          generalNetworkService
        ];

        partOf = [ testRoot ];
        wantedBy = [ testRoot ];
      };

      virtualisation.docker = {
        enable = true;
        autoPrune.enable = true;
      };
      virtualisation.oci-containers.backend = "docker";

      age.secrets = {
        api-test.file = mysecrets + "/api-test.age";
        api-prod.file = mysecrets + "/api-prod.age";

        postgres.file = mysecrets + "/postgres-prod.age";
        openobserve.file = mysecrets + "/openobserve.age";
      };

      # TEST
      # NGINX
      # virtualisation.oci-containers.containers."dohly-nginx-test" = {
      #   image = "nginx:alpine:latest";
      #   ports = [ "7000:7000" ];
      #   log-driver = "journald";
      #   extraOptions = [ "--user=nginx:nginx" ];
      # };

      # API
      virtualisation.oci-containers.containers."dohly-api-test" = {
        image = "dohly-api-test";
        environmentFiles = [
          "/run/agenix/api-test"
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
          "docker-build-dohly-api-test.service"
          testNetworkService
          generalNetworkService
        ];

        requires = [
          "docker-build-dohly-api-test.service"
          testNetworkService
          generalNetworkService
        ];

        partOf = [ testRoot ];
        wantedBy = [ testRoot ];
      };

      systemd.services."docker-build-dohly-api-test" = {
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
          docker load < $(nix-build -I nixpkgs=${pkgs.path} ${testApiPath} -A apiImage --no-out-link --arg imagePostfix '"test"')
        '';

        partOf = [ testRoot ];
        wantedBy = [ testRoot ];
      };

      # FRONT

      virtualisation.oci-containers.containers."dohly-front-test" = {
        image = "dohly-front-test";
        environmentFiles = [
          #"/run/agenix/front-test"
        ];
        dependsOn = [ "dohly-api-test" ];
        ports = [
          "0.0.0.0:7200:5000/tcp"
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
          docker build -t dohly-front-test -f Dockerfile .
        '';
        partOf = [ testRoot ];
        wantedBy = [ testRoot ];
      };

      # Networks
      systemd.services."${testNetwork}" = (
        let
          networkName = "dohly-test";
        in
        {
          path = [ pkgs.docker ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStop = "docker network rm -f ${networkName}";
          };
          script = ''
            docker network inspect ${networkName}|| docker network create ${networkName}
          '';
          partOf = [ testRoot ];
          wantedBy = [ testRoot ];
        }
      );

      systemd.targets."${testRoot}" = {
        unitConfig = {
          Description = "Root target for dohly project test";
        };
        wantedBy = [ "multi-user.target" ];
      };
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

      systemd.services."docker-build-dohly-api-prod" = {
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
          docker load < $(nix-build -I nixpkgs=${pkgs.path} ${prodApiPath} -A apiImage --no-out-link --arg imagePostfix '"prod"')
        '';

        partOf = [ prodRoot ];
        wantedBy = [ prodRoot ];
      };

      # FRONT

      virtualisation.oci-containers.containers."dohly-front-prod" = {
        image = "dohly-front-prod";
        environmentFiles = [
          # "/run/agenix/front-prod"
        ];
        dependsOn = [ "dohly-api-prod" ];
        ports = [
          "0.0.0.0:6200:5000/tcp"
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
      systemd.services."${prodNetwork}" = (
        let
          networkName = "dohly-prod";
        in
        {
          path = [ pkgs.docker ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStop = "docker network rm -f ${networkName}";
          };
          script = ''
            docker network inspect ${networkName}|| docker network create ${networkName}
          '';
          partOf = [ prodRoot ];
          wantedBy = [ prodRoot ];
        }
      );

      systemd.targets."${prodRoot}" = {
        unitConfig = {
          Description = "Root target for dohly project prod";
        };
        wantedBy = [ "multi-user.target" ];
      };

      # GENERAL

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
      systemd.services."${generalNetwork}" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "docker network rm -f dohly-general";
        };
        script = ''
          docker network inspect dohly-general || docker network create dohly-general
        '';
        partOf = [ generalRoot ];
        wantedBy = [ generalRoot ];
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
