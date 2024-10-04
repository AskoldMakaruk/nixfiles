{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  home = {
    username = "askold";
    homeDirectory = "/home/askold";
    stateVersion = "24.05";
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "tilda";
    SHELL = "zsh";
    NIX_SHELL_INIT = "zsh";
    NIXPKGS_ALLOW_UNFREE = "1";
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

    programs.oh-my-posh = {
      enable = true;
      enableZshIntegration = true;
    };

  programs.zsh.enable = true;
  programs.home-manager.enable = true;
}
