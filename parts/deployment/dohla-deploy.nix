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
    batat.dohla.test = {
      database.enable = lib.mkEnableOption "enables test postgres";
      logs.enable = lib.mkEnableOption "enables openobserve platform";
      front.enable = lib.mkEnableOption "enables test frontend";
      api.enable = lib.mkEnableOption "enables test api";
    };
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
      front-test.file = mysecrets + "/front-test.age";
      openobserve.file = mysecrets + "/openobserve.age";
    };
  });
}
