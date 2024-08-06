{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  home-manager.backupFileExtension =
    "backup-"
    + pkgs.lib.readFile "${pkgs.runCommand "timestamp" { } "echo -n `date '+%Y%m%d%H%M%S'` > $out"}";

  home-manager.useGlobalPkgs = true;
  home = {
    username = "askold";
    homeDirectory = "/home/askold";
    stateVersion = "24.05";
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "tilda";
    NIXPKGS_ALLOW_UNFREE = "1";
    NIX_SHELL_INIT = "zsh";
  };

  #   home.file = {
  #     ".config" = {
  #       source = ./config;
  #       recursive = true;
  #     };
  #   };

  programs.git = {
    enable = true;
    userName = "Askold Makaruk";
    userEmail = "askoldmakaruk@gmail.com";
  };

  programs.home-manager.enable = true;
}
