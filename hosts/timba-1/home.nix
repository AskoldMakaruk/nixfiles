{
  inputs,
  lib,
  pkgs,
  pkgs-master,
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
    LD_LIBRARY_PATH = lib.makeLibraryPath [
      "${pkgs.openssl_legacy}/lib/"
      pkgs.icu
    ];
    # DOTNET_ROOT = "${pkgs.dotnet-sdk}";
    DOTNET_ROOT = "${pkgs-master.dotnetCorePackages.sdk_10_0}/share/dotnet/";

    EDITOR = "nvim";
    VISUAL = "nvim";
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  programs.git = {
    enable = true;
    userName = "AskoldMakaruk";
    userEmail = "askoldmakaruk@gmail.com";
  };

  programs.oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh.enable = true;
  programs.home-manager.enable = true;
}
