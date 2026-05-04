{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.forgejo-runner;

  yamlFormat = pkgs.formats.yaml { };
  runnerConfig = yamlFormat.generate "runner-config.yml" {
    log = {
      level = "info";
    };
    runner = {
      file = ".runner";
    };
    cache = {
      enabled = true;
      dir = "/tmp/cache";
    };
    container = {
      docker_host = "unix:///var/run/docker.sock";
      options = "--volume /var/run/docker.sock:/var/run/docker.sock";
    };
  };
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
      default = "ubuntu-latest:host";
      description = "Runner labels. Use ':host' to run workflows directly on the host (needed for Docker access).";
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

      path = [ pkgs.docker pkgs.nodejs pkgs.git ];

      preStart = ''
        export HOME=/var/lib/forgejo-runner
        install -d -o forgejo-runner -g forgejo-runner /var/lib/forgejo-runner
        install -o forgejo-runner -g forgejo-runner -m 0644 ${runnerConfig} /var/lib/forgejo-runner/config.yml
        if [ ! -f /var/lib/forgejo-runner/.runner ]; then
          export HOME=/var/lib/forgejo-runner
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
        Environment = [
          "HOME=/var/lib/forgejo-runner"
          "PATH=/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/bin:${pkgs.git}/bin"
        ];
        ExecStart = "${pkgs.forgejo-runner}/bin/forgejo-runner daemon --config /var/lib/forgejo-runner/config.yml";
        Restart = "always";
        RestartSec = "5s";
        StateDirectory = "forgejo-runner";
        StateDirectoryMode = "0700";

        SupplementaryGroups = [ "docker" ];

        # Hardening
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
        ];
      };
    };

    users.users.forgejo-runner = {
      isSystemUser = true;
      group = "forgejo-runner";
      extraGroups = [ "docker" ];
    };

    users.groups.forgejo-runner = { };

    security.sudo.extraRules = [
      {
        users = [ "forgejo-runner" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/systemctl restart docker-dohly-front-test.service";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/systemctl restart docker-build-dohly-front-test.service";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
