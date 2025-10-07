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
    # dohly-services.containers = {
    #   api = {
    #     containerPort = 5000;
    #     service = "api";
    #     project = "dohla";
    #     env = "production";
    #     hostPort = "8080";
    #     buildPath = "server/DohlaRusnya3.4.and.5/DohlaRusnya.Api/";
    #   };
    # };
    #
    # dohly-services.enable = true;
    # dohly-services.openobserve = {
    #   enable = true;
    #   networks = [
    #     "internal"
    #   ];
    # };
    #
    # dohly-services.database = {
    #   enable = true;
    #   networks = [
    #     "internal"
    #   ];
    # };
    #
    # dohly-services.envs = {
    #   "dohly_test" = {
    #     api = {
    #       enable = true;
    #       env = "production";
    #       containerPort = 5000;
    #       hostPort = 8080;
    #       projectPath = "/home/askold/src/DohlaRusnya/src/server/DohlaRusnya3.4.and.5/DohlaRusnya.Api";
    #       networks = [
    #         "dohly_test"
    #         "internal"
    #       ];
    #     };
    #
    #     front = {
    #       enable = true;
    #       env = "production";
    #       containerPort = 5000;
    #       hostPort = 8081;
    #       projectPath = "/home/askold/src/DohlaRusnya/src/server/DohlaRusnya3.4.and.5/DohlaRusnya.Api";
    #       networks = [
    #         "dohly_test"
    #         "internal"
    #       ];
    #     };
    #
    #   };

      # "dohly_prod" = {
      #
      # };

    };
  };
}
