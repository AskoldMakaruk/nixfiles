{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.batat.tailscale;
in
{
  options.batat.tailscale = {
    enable = lib.mkEnableOption "Enable Tailscale";
    authKeyTag = lib.mkOption {
      type = lib.types.str;
      default = "server";
      description = "Tag associated with preauthorized key";
    };
    limitNetworkInterfaces = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Only accept traffic via the Tailscale interface";
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      extraUpFlags = [
        "--ssh"
        "--advertise-tags=tag:${cfg.authKeyTag}"
      ];
      permitCertUid = "caddy";
    };

    networking.firewall = lib.mkIf cfg.limitNetworkInterfaces {
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };

    systemd.services.tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";
      after = [
        "network-pre.target"
        "tailscale.service"
      ];
      wants = [
        "network-pre.target"
        "tailscale.service"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = with pkgs; ''
        # wait for tailscaled to settle
        sleep 2

        # check if we are already authenticated to tailscale
        status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
        if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
        fi

        # otherwise authenticate with tailscale
        ${tailscale}/bin/tailscale up -authkey tskey-auth
      '';
    };
  };
}
