{
  config,
  inputs,
  pkgs,
  ...
}:
let
  inherit (inputs) mysecrets;
  commonBorgSettings = passSecret: {
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat ${passSecret}";
    };
    environment.BORG_RSH = "ssh -o 'StrictHostKeyChecking=no' -i ${config.age.secrets.borgSshKey.path}";
    extraCreateArgs = "--verbose --stats --checkpoint-interval 600";
    compression = "auto,lzma";
    startAt = "*-*-* 23:45:00";
    user = "root";
    prune.keep = {
      within = "1d";
      daily = 7;
      weekly = 4;
      monthly = -1;
    };
  };
in
{
  # Dump dohly postgres (docker container) before borg runs
  systemd.services.dohly-postgres-dump = {
    description = "Dump dohly PostgreSQL to /var/backup/dohly-postgres";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    path = [ pkgs.docker ];
    script = ''
      mkdir -p /var/backup/dohly-postgres
      docker exec dohly-database pg_dumpall -U prod_api > /var/backup/dohly-postgres/dump.sql
    '';
  };

  services.borgbackup.jobs = {
    # Game data: dohly postgres + garage
    "timba2-game-backups" = commonBorgSettings config.age.secrets.timba2GameBorgPass.path // {
      repo = "ssh://bwul64fb@bwul64fb.repo.borgbase.com/./repo";
      preHook = ''
        systemctl start dohly-postgres-dump.service
      '';
      paths = [
        "/var/backup/dohly-postgres" # dohly postgres dump
        "/var/lib/garage" # garage metadata + data
      ];
      exclude = [
        "/var/lib/garage/meta/snapshots"
      ];
    };

    # Org data: nextcloud (files + postgres) + observe
    "timba2-org-backups" = commonBorgSettings config.age.secrets.timba2OrgBorgPass.path // {
      repo = "ssh://qvc2x039@qvc2x039.repo.borgbase.com/./repo";
      paths = [
        "/data/backups/postgresql" # nextcloud postgres (via postgresqlBackup at 23:15)
        "/var/lib/docker/volumes/dohly-observe-volume/_data" # openobserve settings + accounts
        "/data/nextcloud" # nextcloud files
      ];
      exclude = [
        "/data/nextcloud/data/*/cache"
        "/data/nextcloud/data/appdata_*/preview"
      ];
    };
  };

  age.secrets.borgSshKey.file = mysecrets + "/ssh/ao-code-key.age"; # same append-only key as lenovo
  age.secrets.timba2GameBorgPass.file = mysecrets + "/borg/timba2-game-borg-passfile.age";
  age.secrets.timba2OrgBorgPass.file = mysecrets + "/borg/timba2-org-borg-passfile.age";
}
