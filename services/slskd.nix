{ inputs, pkgs-master, ... }:
let
  inherit (inputs) mysecrets;
in
{

  users.groups."media" = {
    members = [
      "slskd"
      "askold"
    ];
  };

  age.secrets = {
    slskd.file = mysecrets + "/slskd.age";
  };

  services.slskd = {
    package = pkgs-master.slskd;
    enable = true;
    domain = "slskd.localhost";
    settings = {
      directories = {
        #incomplete = "~/Downloads/slsk/incomplete";
        #downloads = "~/Downloads/slsk/complete";
      };
      shares = {
        directories = [
          # TODO: move to directory that's accesable for slskd user
          "/home/askold/Music"
        ];
      };
    };
    environmentFile = "/run/agenix/slskd";
  };
}
