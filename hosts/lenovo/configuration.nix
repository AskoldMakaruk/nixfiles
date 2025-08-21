{
  inputs,
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
    ./../../parts
  ];

  batat = {
    audio.enable = true;
    shell.enable = true;
    kde.enable = true;
    nvim.enable = true;
    jetbrains.enable = true;
    vscode.enable = true;
    piracy.enable = false;
    dohla.enable = true;
    development.enable = true;
  };

  # boot.initrd.kernelModules = [ "amdgpu" ];
  networking.hostName = "nixos"; # Define your hostname.
  networking.wireless.enable = true; # Enables wireless support via wpa_supplicant.
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.networkmanager.ethernet.macAddress = "C0:35:32:01:92:27";

  # Enable networking
  #networking.networkmanager.enable = true;

  age = {
    identityPaths = [ "/home/askold/.ssh/agenix_key" ];
    secrets = {
      api = {
        file = mysecrets + "/api-prod.age";
      };
      postgres = {
        file = mysecrets + "/postgres-prod.age";
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
    extraSpecialArgs = { inherit inputs; };
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
