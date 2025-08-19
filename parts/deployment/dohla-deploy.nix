{
  lib,
  config,
  ...
}:
{
  options = {
    batat.dohla.enable = lib.mkEnableOption "enables deployment of dohla rusnya services";
  };

  config = lib.mkIf config.batat.dohla.enable {
    services.docker-services.enableAll = true;
  };
}
