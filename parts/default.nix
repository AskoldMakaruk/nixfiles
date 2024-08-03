{ pkg, lib, ... }: {
  imports = [ ./console.nix ./editor.nix ./database.nix ];

  batat.console.enable = lib.mkDefault false;
  batat.editor.enable = lib.mkDefault false;
  batat.database.enable = lib.mkDefault false;
}
