{
  inputs,
  config,
  lib,
  pkgs,
  users,
  ...
}:

{
  options = {
    batat.piracy.enable = lib.mkEnableOption "enables piracy modules";
  };

  config = lib.mkIf config.batat.piracy.enable {
    # Allow unfree packages
    nixpkgs.config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "aspnetcore-runtime-6.0.36"
        "aspnetcore-runtime-wrapped-6.0.36"
        "dotnet-sdk-6.0.428"
        "dotnet-sdk-wrapped-6.0.428"
      ];
    };

    environment.systemPackages = with pkgs; [
      jellyfin
      jellyfin-web
      jellyfin-ffmpeg
    ];

    # services.jellyfin = {
    #   enable = true;
    #   openFirewall = true;
    #   user = "askold";
    # };

    # services.sonarr = {
    #   enable = true;
    #   openFirewall = true;
    #   user = "askold";
    #   dataDir = "/home/askold/Downloads/sonarr/";
    # };

    # services.jackett = {
    #   enable = true;
    #   openFirewall = true;
    #   user = "askold";
    # };
  };
}
