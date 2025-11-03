{
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (inputs) mysecrets;
in
{
  imports = [
    ./dohla-general.nix
    # ./dohla-prod.nix
    ./dohla-test.nix
  ];

  options = {
    batat.dohla.enable = lib.mkEnableOption "enables deployment of dohla rusnya services";
  };

  config = lib.mkIf config.batat.dohla.enable ({
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
    };
    virtualisation.oci-containers.backend = "docker";

    age.secrets = {
      api-test.file = mysecrets + "/api-test.age";
      api-prod.file = mysecrets + "/api-prod.age";
      openobserve.file = mysecrets + "/openobserve.age";
    };
  });
}
