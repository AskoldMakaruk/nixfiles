{
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (inputs) mysecrets;
  common-excludes = [
    ".cache"
    "cache2" # firefox
    "Cache"
    ".config/Slack/logs"
    ".config/Code/CachedData"
    ".container-diff"
    ".npm/_cacache"
    # Work related dirs
    "node_modules"
    "bower_components"
    "_build"
    ".tox"
    "venv"
    ".venv"
    ".env"
    "bin"
    "obj"
    ".idea"
    "target"
    ".vite"
    ".svelte-kit"
    ".godot"
  ];
  basicBorgJob = name: {
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat ${config.age.secrets.mediaBorgPass.path}";
    };
    environment.BORG_RSH = "ssh -o 'StrictHostKeyChecking=no' -i ${config.age.secrets.borgSshKey.path}";
    extraCreateArgs = "--verbose --stats --checkpoint-interval 600";
    repo = "ssh://cqs0r9y0@cqs0r9y0.repo.borgbase.com/./repo";
    # compression = "zstd,1";
    compression = "auto,lzma";
    startAt = "daily";
    user = "askold";
    prune.keep = {
      within = "1d";
      daily = 7;
      weekly = 4;
      monthly = -1;
    };
  };
in
{
  services.borgbackup.jobs."code-backups-to-remote" = basicBorgJob "backups/code" // {
    paths = [
      "/home/askold/src"
      "/home/askold/secrets"
    ];
    exclude = [ "fora" ] ++ common-excludes;
  };
  age.secrets.borgSshKey.file = mysecrets + "/ssh/ao-code-key.age";
  age.secrets.borgSshKey.owner = "askold";
  age.secrets.mediaBorgPass.file = mysecrets + "/borg-passfile.age";
  age.secrets.mediaBorgPass.owner = "askold";
}
# backupFrequency = lib.mkOption {
#   type = lib.types.enum [
#     "daily"
#     "weekly"
#     "monthly"
#     "yearly"
#   ];
#   default = "daily";
#   description = "Frequency for files and folders to be backed up";
