{ config, inputs, lib, pkgs, ...}:
{
options = {
    batat.jetbrains.enable = lib.mkEnableOption "enables jetbrains toolbox";

  };

  config = lib.mkIf config.batat.jetbrains.enable{

    environment.systemPackages = with pkgs; [jetbrains-toolbox];
  };
}
