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
    sessionPath = [ "$HOME/.dotnet/tools/" ];
  };

  home.sessionVariables = {
    LD_LIBRARY_PATH = "${pkgs.openssl_legacy}/lib/";
    DOTNET_ROOT = "${pkgs.dotnetCorePackages.runtime_9_0}/share/dotnet/";
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "konsole";
    # SHELL = "zsh";
    # NIX_SHELL_INIT = "zsh";
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
