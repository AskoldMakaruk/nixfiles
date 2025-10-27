{
  pkgs,
  lib,
  config,
  ...
}:
lib.mkIf config.batat.development.enable {
  environment.systemPackages = with pkgs; [

    # HTTP UI client postman alternative
    bruno

    # current dotnet platform
    dotnetCorePackages.sdk_9_0
    dotnetCorePackages.runtime_9_0
    #dotnetCorePackages.aspnetcore_9_0
    # old dotnet sdk
    # dotnet-sdk

    # dotnet entity framework toool
    dotnet-ef
  ];
}
