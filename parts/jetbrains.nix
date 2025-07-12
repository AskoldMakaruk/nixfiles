{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  options = {
    batat.jetbrains.enable = lib.mkEnableOption "enables jetbrains toolbox";

  };

  config = lib.mkIf config.batat.jetbrains.enable {

    nixpkgs.overlays = with inputs.jbr-overlay.overlays; [ editorsOverlay ];

    environment.systemPackages = with pkgs; [
      jetbrains.rider
    ];
  };
}
