{ pkg, lib, ... }:
{
  imports = [
    ./console.nix
    ./editor/default.nix
    ./database.nix
    ./jetbrains.nix
  ];

  batat.console.enable = lib.mkDefault false;
  batat.editor.enable = lib.mkDefault false;
  batat.database.enable = lib.mkDefault false;
  batat.jetbrains.enable = lib.mkDefault false;
}
