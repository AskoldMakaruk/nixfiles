{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.forgejo-runner;
in
{
  options.services.forgejo-runner = {
    enable = lib.mkEnableOption "Forgejo Actions Runner";

    tokenFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the registration token file (from Forgejo UI → Site Admin → Actions → Runners → Create Runner)";
    };

    name = lib.mkOption {
      type = lib.types.str;
      default = "forgejo-runner";
      description = "Runner name as shown in Forgejo UI";
    };

    url = lib.mkOption {
      type = lib.types.str;
      default = "https://git.askold.dev";
      description = "Forgejo instance URL";
    };

    labels = lib.mkOption {
      type = lib.types.str;
      default = "ubuntu-latest:docker://catthehacker/ubuntu:runner-latest";
      description = "Runner labels and Docker image mappings";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.forgejo-runner = {
      description = "Forgejo Actions Runner";
      after = [
        "network-online.target"
        "docker.service"
      ];
      wants = [
        "network-online.target"
        "docker.service"
      ];
      wantedBy = [ "multi-user.target" ];

      preStart = ''
        if [ ! -f /var/lib/forgejo-runner/.runner ]; then
          install -d -o forgejo-runner -g forgejo-runner /var/lib/forgejo-runner
          ${pkgs.forgejo-runner}/bin/forgejo-runner register \
            --name "${cfg.name}" \
            --token "$(cat ${cfg.tokenFile})" \
            --labels "${cfg.labels}" \
            --no-interactive \
            --instance "${cfg.url}"
        fi
      '';

      serviceConfig = {
        Type = "exec";
        User = "forgejo-runner";
        Group = "forgejo-runner";
        WorkingDirectory = "/var/lib/forgejo-runner";
        ExecStart = "${pkgs.forgejo-runner}/bin/forgejo-runner daemon";
        Restart = "always";
        RestartSec = "5s";
        StateDirectory = "forgejo-runner";
        StateDirectoryMode = "0700";

        SupplementaryGroups = [ "docker" ];

        # Hardening
        CapabilityBoundingSet = "";
        DeviceAllow = "";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = false;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@cpu-emulation"
          "~@debug"
          "~@keyring"
          "~@memlock"
          "~@obsolete"
          "~@privileged"
          "~@setuid"
        ];
      };
    };

    users.users.forgejo-runner = {
      isSystemUser = true;
      group = "forgejo-runner";
      extraGroups = [ "docker" ];
    };

    users.groups.forgejo-runner = { };
  };
}
