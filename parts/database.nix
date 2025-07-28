{
  config,
  lib,
  pkgs,
  ...
}:

{
  options = {
    batat.database.enable = lib.mkEnableOption "enables databse modules";
  };

  config = lib.mkIf config.batat.database.enable {
    services.postgresql = {
      enable = true;
      enableTCPIP = true;
      settings.port = 5432;
      ensureDatabases = [ "dev" ];
      authentication = pkgs.lib.mkOverride 10 ''
        #type  database  DBuser origin-address auth-method
        host  all       all    127.0.0.1/32   trust
      '';

      initialScript = pkgs.writeText "backend-initScript" ''
        CREATE ROLE askold WITH LOGIN PASSWORD 'askold' CREATEDB;
        CREATE DATABASE dev;
        GRANT ALL PRIVILEGES ON DATABASE dev TO askold;
      '';
    };
  };
}
