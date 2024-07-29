{ inputs, lib, pkgs, ... }:

{
  home = {
    username ="askold";
    homeDirectory = "/home/askold";
    stateVersion = "24.05";
  };
  
  programs.git = {
    enable = true;
    userName = "Askold Makaruk";
    userEmail = "askoldmakaruk@gmail.com";
  };
  
  programs.home-manager.enable = true;
}
