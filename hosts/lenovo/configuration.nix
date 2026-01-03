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
    ../../parts/wireguard.nix
    ../../services/affine.nix
    ../../services/espanso.nix
    #../../services/minio.nix
    ../../services/garage.nix
    ../../services/slskd.nix
    ../../parts/keyd.nix
  ];

  batat = {
    audio.enable = true;
    shell.enable = true;
    # kde.enable = true;
    nvim.enable = true;
    jetbrains.enable = true;
    vscode.enable = true;
    piracy.enable = false;
    development.enable = true;
    affine.enable = false;
    gaming.enable = true;
    programs.enable = true;

    dohla.enable = true;
    dohla.test = {
      database.enable = true;
      logs.enable = false;
      api.enable = false;
      front.enable = false;
    };
  };

  # boot.initrd.kernelModules = [ "amdgpu" ];
  networking.hostName = "nixos"; # Define your hostname.

  networking.wireless.enable = true; # Enables wireless support via wpa_supplicant.
  # networking.wireless.iwd.enable = true;
  # networking.wireless.iwd.settings.Network.EnableIPv6 = true;
  # networking.wireless.iwd.settings.Settings.AutoConnect = true;
  networking.firewall.allowedTCPPorts = [
    22
    8080
  ];
  #  networking.networkmanager.ethernet.macAddress = "C0:35:32:01:92:27";

  networking.wireguard.interfaces = {
    wg0 = {
      ips = [
        "10.5.5.10/24"
      ];
    };
  };

  services.xserver.enable = true;

  services = {

    # android ass DE
    desktopManager.lomiri.enable = false;

    # too flashy and alt tab doensn't work as well as shortcuts from non en layout
    desktopManager.cosmic.enable = false;

    # fun kino DE, unstable as monkey bananzas
    # i cannot resize a fucken window
    # telegram acts like a bitch, incoming message brings window on top # fixed in tg settings
    desktopManager.pantheon.enable = false;

    # gnomification (in a bad way)
    # never again (maybe)
    displayManager.gdm.enable = false;
    desktopManager.gnome.enable = false;
    # the slim gnomy
    gnome.core-apps.enable = false;
    gnome.core-developer-tools.enable = false;
    gnome.games.enable = false;

    # kde plasma. the base shit
    desktopManager.plasma6 = {
      enable = true;
      enableQt5Integration = true; # disable for qt6 full version
    };
    displayManager = {
      #defaultSession = "plasma";
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    };

    # no shortcuts. no app launcher. no fucking wifi.
    xserver.desktopManager.xfce.enable = false;

  };

  # the slim gnomy
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-user-docs
  ];
  # Enable networking
  # networking.networkmanager.enable = true;
  # networking.networkmanager.wifi.backend = "iwd";

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

  # systemd.services.fprintd = {
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig.Type = "simple";
  # };

  # services.fprintd.enable = true;
  # services.fprintd.tod.enable = true;
  # services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;

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

  virtualisation.docker.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.askold = {
    isNormalUser = true;
    description = "Askold";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
  };

  programs.nix-ld.enable = true;
  programs.nh = {
    enable = true;
    flake = "/home/askold/.dotfiles";
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      AllowUsers = null; # Allows all users by default. Can be [ "user1" "user2" ]
      UseDns = true;
      X11Forwarding = false;
      PermitRootLogin = "prohibit-password"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
    };
  };

  system.stateVersion = "24.05"; # don't change

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
