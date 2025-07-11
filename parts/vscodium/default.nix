{
  inputs,
  config,
  lib,
  pkgs,
  users,
  ...
}:

{
  options = {
    batat.vscode.enable = lib.mkEnableOption "enables vscode modules";
  };

  config = lib.mkIf config.batat.vscode.enable {
    home-manager.users.askold = {
      ## VSCODE God forgive me
      programs.vscode = {
        enable = true;
        package = pkgs.vscodium.fhs;
        profiles.default.extensions = with pkgs.vscode-extensions; [
          dracula-theme.theme-dracula
          vscodevim.vim
          yzhang.markdown-all-in-one
        ];
      };

      home.file = {
        ".config/VSCodium" = {
          source = ./config/VSCodium;
          recursive = true;
        };
      };
    };
  };
}
