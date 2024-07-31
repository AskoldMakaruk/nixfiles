{pkg, lib, ...}:
{
  imports = [
    ./console.nix
    ./editor.nix
  ];

  batat.console.enable = lib.mkDefault false;
  batat.editor.enable = lib.mkDefault false;
}
