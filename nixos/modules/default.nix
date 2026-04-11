{ ... }:
{
  imports = [
    ./acme.nix
    ./borgbackup.nix
    ./fluent-bit.nix
    ./nextcloud.nix
    ./tailscale.nix
  ];
}
