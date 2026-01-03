{ inputs, ... }:
let
  inherit (inputs) mysecrets;
in
{
  age.secrets = {
    slskd.file = mysecrets + "/slskd.age";
  };
  services.slskd = {
    enable = true;
    domain = "slskd.localhost";
    settings = {
      directories = {
        #incomplete = "~/Downloads/slsk/incomplete";
        #downloads = "~/Downloads/slsk/complete";
      };
      shares = {
        directories = [
          "/home/askold/Music/"
        ];
      };
    };
    environmentFile = "/run/agenix/slskd";
  };
}
