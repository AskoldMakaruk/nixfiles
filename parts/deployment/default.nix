{ lib, ... }:
{
  imports = [
    ./dohla-deploy.nix
  ];

  batat.dohla.enable = lib.mkDefault false;
}
