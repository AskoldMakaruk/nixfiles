{ inputs, lib, pkgs, ... }:

{
  home = {
    username ="askold";
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
  
  programs.git = {
    enable = true;
    userName = "Askold Makaruk";
    userEmail = "askoldmakaruk@gmail.com";
  };
  
  programs.home-manager.enable = true;
}
