{
  config,
  lib,
  ...
}:
{
  options = {
    batat.audio.enable = lib.mkEnableOption "enables audio via pipwire";

  };

  config = lib.mkIf config.batat.audio.enable {

    # Whether to enable the RealtimeKit system service, which hands out realtime scheduling priority to user processes on demand.
    # For example, PulseAudio and PipeWire use this to acquire realtime priority.
    security.rtkit.enable = true;
    # Enable sound with pipewire.
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
