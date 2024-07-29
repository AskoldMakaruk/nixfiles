{pkg, lib, ...}:
{
  imports = [
    ./console.nix
  ];

  batat.console.enable = lib.mkDefault false;
}
