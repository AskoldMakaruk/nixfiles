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
    #./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
    inputs.nixvim.nixosModules.nixvim
    ../../parts
    ../../nixos/modules
    ../../parts/wireguard.nix
    ../../services/affine.nix
    # ../../services/minio.nix
    ../../services/garage.nix
    ./nginx.nix

    "${inputs.nixpkgs}/nixos/modules/virtualisation/digital-ocean-config.nix"
    inputs.nixos-generators.nixosModules.all-formats
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

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    22
    80
    443
    8080
    5666
    7200
  ];
  networking.hostId = "bd246190";
  networking.hostName = "timba-1";

  system.stateVersion = "25.05";

  networking.wireguard.interfaces = {
    wg0 = {
      ips = [
        "10.5.5.30/24"
      ];
    };
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 4096;
    }
  ];

  batat = {
    tailscale.enable = true;
    fluent-bit.enable = true;
    shell.enable = true;
    nvim.enable = true;
    development.enable = true;
    affine.enable = true;

    dohla.enable = false;
    dohla.test = {
      database.enable = false;
      logs.enable = false;
      api.enable = false;
      front.enable = false;
    };
  };

  age = {
    identityPaths = [ "/home/askold/.ssh/agenix_key" ];
    secrets = {
      api = {
        file = mysecrets + "/api-prod.age";
      };
      postgres = {
        file = mysecrets + "/postgres-prod.age";
      };
      wg_key = {
        file = mysecrets + "/nout_wireguard_key.age";
      };
      wg_endpoint = {
        file = mysecrets + "/wireguard_endpoint_ip.age";
      };
      telegram-bot.file = inputs.mysecrets + "/telegram-bot-dev.age";
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
    initialPassword = "bbb";
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

  services.do-agent.enable = true;

  services.murmur = {
    enable = true;
    openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    python3
    mumble
  ];

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
}
