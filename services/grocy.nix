{ ... }:
{
  services.grocy = {
    enable = true;
    hostName = "grocy.askold.dev";
    dataDir = "/data/grocy";
    nginx.enableSSL = false;
    settings = {
      currency = "UAH";
      culture = "en";
    };
  };
}
