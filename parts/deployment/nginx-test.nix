{
  pkgs,
  config,
  ...
}:

let
  nginxCustomImage = pkgs.dockerTools.buildImage {
    name = "dohly-nginx-test";
    tag = "latest";

    fromImage = pkgs.dockerTools.pullImage {
      imageName = "nginx";
      imageDigest = "sha256:61e01287e546aac28a3f56839c136b31f590273f3b41187a36f46f6a03bbfe22";
      finalImageName = "nginx";
      finalImageTag = "alpine";
      sha256 = "sha256-WOmQfXnbHl1mFRvswZrC4VIJ8gPg5yYIGj+iv8xuvMs=";
    };

    copyToRoot = null;

    runAsRoot = ''
      #!${pkgs.runtimeShell}
      ${pkgs.dockerTools.shadowSetup}
    '';

    config = {
      Cmd = [
        "nginx"
        "-g"
        "daemon off;"
      ];
      ExposedPorts = {
        "7000/tcp" = { };
      };
      WorkingDir = "/usr/share/nginx/html";

      # Copy custom nginx configuration
      copyToRoot = pkgs.buildEnv {
        name = "nginx-config-root";
        paths = [
          (pkgs.writeTextDir "etc/nginx/conf.d/default.conf" (builtins.readFile ./nginx.conf))
        ];
      };
    };
  };
in
{
  config = {
    systemd.services.docker-preload = {
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ config.virtualisation.docker.package ];
      script = ''
        docker load -i ${nginxCustomImage}
      '';
      serviceConfig = {
        RemainAfterExit = true;
        Type = "oneshot";
      };
    };

    virtualisation.oci-containers.containers."dohly-nginx-test" = {
      image = "dohly-nginx-test:latest";
      ports = [ "7000:7000" ];
      log-driver = "journald";
      #extraOptions = [ "--user=nginx:nginx" ]; # Use nginx user that exists in Alpine image
    };
  };
}
