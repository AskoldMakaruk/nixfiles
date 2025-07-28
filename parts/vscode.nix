{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    batat.mscode.enable = lib.mkEnableOption "enables vscode blyadskiy editor";

  };

  config = lib.mkIf config.batat.mscode.enable {

    environment.systemPackages = with pkgs; [
      vscode
    ];
  };
}
