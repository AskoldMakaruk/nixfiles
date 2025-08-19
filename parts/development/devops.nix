{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.batat.development.enable {

  virtualisation.docker.enable = true;
  virtualisation.docker.package = pkgs.docker_25;
  # virtualisation.containers.enable = true;
  # virtualisation = {
  #   podman = {
  #     enable = true;
  #
  #     # Create a `docker` alias for podman, to use it as a drop-in replacement
  #     dockerCompat = true;
  #
  #     # Required for containers under podman-compose to be able to talk to each other.
  #     defaultNetwork.settings.dns_enabled = true;
  #   };
  # };
  #
  environment.systemPackages = with pkgs; [
    # must have
    systemctl-tui

    dive # look into docker image layers
    podman-tui # status of containers in the terminal
    docker-compose # start group of containers for dev
    podman-compose # start group of containers for dev
  ];
}
