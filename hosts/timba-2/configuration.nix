{
  inputs,
  system,
  config,
  pkgs,
  ...
}:
let
  inherit (inputs) mysecrets;
in
{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
    inputs.nixvim.nixosModules.nixvim
    ../../parts
    ../../nixos/modules
    ../../services/affine.nix
    ../../services/garage.nix
    ../../services/grocy.nix
    ../../services/forgejo.nix
    ../../services/forgejo-runner.nix
    ./nextcloud.nix
    ./backup.nix
    ../../services/suwayomi.nix
  ];

  nix = {
    settings = {
      tarball-ttl = 300;
      auto-optimise-store = true;
      experimental-features = "nix-command flakes";
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    22
    80
    443
    8080
    5666
    7200
    7300
  ];
  #  networking.hostId = "bd246190";
  networking.hostName = "timba-2";

  system.stateVersion = "25.11";

  batat = {
    shell.enable = true;
    fluent-bit.enable = true;
    nvim.enable = true;
    development.enable = true;
    affine.enable = false;

    tailscale.enable = true;

    forgejo.enable = true;

    suwayomi.enable = true;

    dohla.enable = true;
    dohla.test = {
      database.enable = true;
      logs.enable = true;
      api.enable = true;
      front.enable = true;
    };
  };

  services.forgejo-runner = {
    enable = true;
    tokenFile = config.age.secrets.forgejoRunnerToken.path;
  };

  age = {
    identityPaths = [ "/home/askold/.ssh/agenix_key" ];
    secrets = {
      api = {
        file = mysecrets + "/api-test.age";
      };
      postgres = {
        file = mysecrets + "/postgres-prod.age";
      };
      telegram-bot.file = inputs.mysecrets + "/telegram-bot.age";
      telegram-bot.owner = "askold";
      forgejoRunnerToken = {
        file = mysecrets + "/forgejo/runner-token.age";
        owner = "forgejo-runner";
        group = "forgejo-runner";
      };
    };
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;

      pkgs-master = import inputs.nixpkgs-master {
        inherit system;
        config.allowUnfree = true;
      };
    };
    users = {
      askold = import ./home.nix;
    };
    backupFileExtension =
      "backup-"
      + pkgs.lib.readFile "${pkgs.runCommand "timestamp" { } "echo -n `date '+%Y%m%d%H%M%S'` > $out"}";
    useGlobalPkgs = false;
  };

  users.users.askold = {
    isNormalUser = true;
    #    initialPassword = "bbb";
    description = "Askold";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAG+yaR+V4osEzcipG2R2Tdmu7ZWswe4IZNpaXNOkzTu askold@nixos"
      ];
    };
  };

  users.users.root = {
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAG+yaR+V4osEzcipG2R2Tdmu7ZWswe4IZNpaXNOkzTu askold@nixos"
      ];
    };
  };

  programs.nix-ld.enable = true;
  programs.nh = {
    enable = true;
    flake = "/home/askold/.dotfiles";
  };

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      UseDns = true;
      X11Forwarding = false;
      PermitRootLogin = "yes";
    };
  };
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
