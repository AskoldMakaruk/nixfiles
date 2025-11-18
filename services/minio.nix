{ inputs, ... }:
let
  inherit (inputs) mysecrets;
in
{
  config = {

    age.secrets = {
      minio.file = mysecrets + "/minio.age";
    };

    services.minio = {
      enable = true;
      browser = true;
      consoleAddress = "0.0.0.0:5550";

      listenAddress = "0.0.0.0:5500";
      rootCredentialsFile = "/run/agenix/minio";
    };
  };
}
