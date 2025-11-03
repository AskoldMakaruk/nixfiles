{ name }:
{
  config = {
    virtualisation.oci-containers.containers."${name}" = {
      image = "dohly-api-prod";
      environmentFiles = [
        "/run/agenix/api-prod"
      ];
      dependsOn = [ "dohly-database" ];
      ports = [
        "0.0.0.0:6100:5000/tcp"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=dohly-api-prod"
        "--network=dohly-prod"
        "--network=dohly-general"
      ];
    };

  };
}
