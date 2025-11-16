{
  config,
  lib,
  ...
}:
{
  options = {
    batat.kde.enable = lib.mkEnableOption "enables kde desktop environment";

  };

  config = lib.mkIf config.batat.kde.enable {

    # Enable the X11 windowing system.
    # You can disable this if you're only using the Wayland session.
    services.xserver.enable = true;

    programs.kdeconnect.enable = true;

    # Enable the KDE Plasma Desktop Environment.
    services = {
      desktopManager.plasma6 = {
        enable = true;
        enableQt5Integration = true; # disable for qt6 full version
      };
      displayManager = {
        defaultSession = "plasma";
        sddm = {
          enable = true;
          #wayland.enable = true;
        };
      };
    };

  };
}
