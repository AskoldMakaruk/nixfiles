{
  pkgs,
  lib,
  config,
  inputs,
  pkgs-master,
  ...
}:
lib.mkIf config.batat.development.enable {
  environment.systemPackages = with pkgs-master; [

    # HTTP UI client postman alternative
    #bruno

    # current dotnet platform
    #unstable.curl
    #dotnetCorePackages.runtime_9_0
    dotnetCorePackages.sdk_10_0
    #dotnetCorePackages.aspnetcore_9_0
    # old dotnet sdk
    #dotnet-sdk

    # dotnet entity framework toool
    #dotnet-ef
    #
    #dotnet
  ];
}
