{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ../../parts/shell/tmux.nix ];
  home = {
    username = "askold";
    homeDirectory = "/home/askold";
    stateVersion = "25.05";
    sessionPath = [ "$HOME/.dotnet/tools/" ];
  };

  home.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnetCorePackages.runtime_9_0}/share/dotnet/";
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "ghostty";
    # fix for wayland not working
    # https://www.reddit.com/r/NixOS/comments/1df2oxc/kde_6_wayland_not_working_with_sddm/
    # SHELL = "zsh";
    # NIX_SHELL_INIT = "zsh";
    NIXPKGS_ALLOW_UNFREE = "1";
    LD_LIBRARY_PATH = "${pkgs.openssl_legacy}/lib/";
    # LD_LIBRARY_PATH = "${lib.makeLibraryPath [
    #   pkgs.openssl
    # ]}";
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
  xsession.enable = true;
  programs.bash.enable = true;
  programs.zsh.enable = true;
  programs.home-manager.enable = true;
}
