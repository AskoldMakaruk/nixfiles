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
    ../../parts/wireguard.nix
    ../../services/affine.nix
    ../../services/espanso.nix
    ../../services/minio.nix

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

  batat = {
    shell.enable = true;
    nvim.enable = true;
    dohla.enable = true;
    development.enable = true;
    affine.enable = true;
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
      PermitRootLogin = "prohibit-password";
    };
  };
}
