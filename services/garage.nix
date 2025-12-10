{ inputs, pkgs, ... }:
let
  inherit (inputs) mysecrets;
in
{
  config = {

    age.secrets = {
      garage.file = mysecrets + "/garage.age";
    };

    services.garage = {
      package = pkgs.garage;
      enable = true;
      environmentFile = "/run/agenix/garage";
      settings = {
        metadata_dir = "/var/lib/garage/meta";
        data_dir = "/var/lib/garage/data";
        db_engine = "sqlite";

        replication_factor = 1;

        s3_api = {

          s3_region = "garage";
          api_bind_addr = "[::]:3900";
          root_domain = ".s3.garage.localhost";
        };

        s3_web = {

          bind_addr = "[::]:3902";
          root_domain = ".web.garage.localhost";
          index = "index.html";
        };

        admin = {
          api_bind_addr = "[::]:5550";
        };

        #rpc_secret = "4425f5c26c5e11581d3223904324dcb5b5d5dfb14e5e7f35e38c595424f5f1e6";
        rpc_bind_addr = "[::]:3901";
        rpc_bind_outgoing = false;
        #admin_token = "$(openssl rand -base64 32)"
        #metrics_token = "$(openssl rand -base64 32)"
      };
    };
  };
}
