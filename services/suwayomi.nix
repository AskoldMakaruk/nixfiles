{ lib, config, ... }:
{
  options.batat.suwayomi.enable = lib.mkEnableOption "enables Suwayomi manga reader server";

  config = lib.mkIf config.batat.suwayomi.enable {
    services.suwayomi-server = {
      enable = true;

      dataDir = "/var/data/mangas";

      user = "suwayomi";
      group = "suwayomi";

      openFirewall = false;

      settings = {
        server = {
          ip = "0.0.0.0";
          port = 5667;
          downloadAsCbz = true;
        };
      };
    };
  };
}
