{
  inputs,
  config,
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
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
    vscode.enable = true;
    gaming.enable = true;
    jetbrains.enable = true;
    mscode.enable = true;
  };

  virtualisation.docker.enable = true;

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

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "uk";

  users.users.askold = {
    isNormalUser = true;
    description = "askold";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  system.stateVersion = "25.05"; # Did you read the comment?
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
