{
  lib,
  config,
  pkgs,
  ...
}:
let
  mkDockerNetwork = import ./docker-network.nix;
  mkDockerBuild = import ./docker-build.nix;
in
{

  imports = [ ./nginx-test.nix ];
  options = {
    batat.dohla.enable = lib.mkEnableOption "enables deployment of dohla rusnya services";
  };

  config = lib.mkIf config.batat.dohla.enable (
    let
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
      # TEST
      # PROXY
      virtualisation.oci-containers.containers."dohly-proxy-test" = {
        image = "dohly-proxy-test";
        environmentFiles = [
          "/run/agenix/api-test"
          #"/home/askold/src/DohlaRusnya/src/server/DohlaRusnya3.4.and.5/DohlaRusnya.Api/.env"
        ];
        # dependsOn = [ "dohly-database" ];
        ports = [
          "0.0.0.0:7000:5000/tcp"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=dohly-proxy-test"
          "--network=dohly-test"
          "--network=dohly-general"
        ];
      };

      systemd.services."docker-dohly-proxy-test" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "always";
          RestartMaxDelaySec = lib.mkOverride 90 "1m";
          RestartSec = lib.mkOverride 90 "100ms";
          RestartSteps = lib.mkOverride 90 9;
        };

        after = [
          "docker-build-dohly-proxy-test.service"
          testNetworkService
          generalNetworkService
        ];

        requires = [
          "docker-build-dohly-proxy-test.service"
          testNetworkService
          generalNetworkService
        ];

        partOf = [ testRoot ];
        wantedBy = [ testRoot ];
      };

      systemd.services."docker-build-dohly-proxy-test" = mkDockerBuild {
        inherit pkgs;
        projectPath = testProxyPath;
        packageName = "proxy";
        envName = "test";
        root = testRoot;
        port = "7100";
      };

      # API
      virtualisation.oci-containers.containers."dohly-api-test" = {
        image = "dohly-api-test";
        environmentFiles = [
          "/run/agenix/api-test"
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

      systemd.services."docker-build-dohly-api-test" = mkDockerBuild {
        inherit pkgs;
        projectPath = testApiPath;
        packageName = "apiImage";
        envName = "test";
        root = testRoot;
        port = "7100";
      };

      # FRONT
      virtualisation.oci-containers.containers."dohly-front-test" = {
        image = "dohly-front-test:latest";
        environmentFiles = [
          #"/run/agenix/front-test"
        ];
        dependsOn = [ "dohly-api-test" ];
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
          docker build -t dohly-front-test:latest -f Dockerfile .
        '';
        partOf = [ testRoot ];
        wantedBy = [ testRoot ];
      };

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
  );
}
