{ lib, ... }:
{
  imports = [
    ./audio.nix
    ./basic.nix
    ./shell/default.nix
    ./nvim/default.nix
    ./database.nix
    ./jetbrains.nix
    ./vscodium/default.nix
    ./piracy.nix
    ./gaming.nix
    ./kde.nix
    ./vscode.nix
    ./development/default.nix
  ];

  batat.audio.enable = lib.mkDefault true;
  batat.basic.enable = lib.mkDefault true;
  batat.kde.enable = lib.mkDefault false;
  batat.shell.enable = lib.mkDefault false;
  batat.nvim.enable = lib.mkDefault false;
  batat.database.enable = lib.mkDefault false;
  batat.jetbrains.enable = lib.mkDefault false;
  batat.vscode.enable = lib.mkDefault false;
  batat.piracy.enable = lib.mkDefault false;
  batat.gaming.enable = lib.mkDefault false;
  batat.mscode.enable = lib.mkDefault false;
  batat.development.enable = lib.mkDefault false;
}
