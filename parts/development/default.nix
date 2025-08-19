{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.batat.development;
in
{
  imports = [
    ./backend.nix
    ./devops.nix
    ./frontend.nix
  ];

  options = {
    batat.development.enable = lib.mkEnableOption "enables development modules";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # TUI for git
      lazygit
      # git
      git
    ];
  };
}
