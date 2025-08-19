{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.batat.development.enable {
  environment.systemPackages = with pkgs; [
    nodejs
    nodePackages.npm
  ];
}
