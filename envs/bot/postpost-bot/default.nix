{stdenv, pkgs}=import <nixpkgs> {};
  rust = import ../../rust/unstable/default.nix;

  dev = pkgs.mkShell ''
  ${rust}

  export INVITE_LINK=https://t.me/+6bXcm4nwNZs0NDJi
'';




