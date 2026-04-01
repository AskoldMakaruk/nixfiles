{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.batat.development.enable {

  virtualisation.docker.enable = true;
  virtualisation.docker.rootless.setSocketVariable = false;
  virtualisation.docker.rootless.enable = false;
  virtualisation.docker.package = pkgs.docker_25;
  # virtualisation.containers.enable = true;
  environment.systemPackages = with pkgs; [
    # must have
    systemctl-tui

    # dive # look into docker image layers
    #    podman-tui # status of containers in the terminal
    docker-compose # start group of containers for dev
    #    podman-compose # start group of containers for dev
  ];
}
