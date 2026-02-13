{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-master,
  ...
}:
{
  options = {
    batat.jetbrains.enable = lib.mkEnableOption "enables jetbrains toolbox";

  };

  config = lib.mkIf config.batat.jetbrains.enable {

    #nixpkgs.overlays = with inputs.jbr-overlay.overlays; [ editorsOverlay ];

    environment.systemPackages = with pkgs-master; [
      jetbrains.webstorm
      jetbrains.rider
    ];
  };
}
