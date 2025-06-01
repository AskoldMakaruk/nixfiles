{
  inputs,
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
    inputs.nixvim.nixosModules.nixvim
    ./parts
  ];

  batat = {
    console.enable = true;
    nvim.enable = true;
    database.enable = false;
    jetbrains.enable = true;
    vscode.enable = true;
    piracy.enable = false;
  };

  # boot.initrd.kernelModules = [ "amdgpu" ];
  networking.hostName = "nixos"; # Define your hostname.
  networking.wireless.enable = true; # Enables wireless support via wpa_supplicant.
  networking.firewall.allowedTCPPorts = [ 22 ];

  # Enable networking
  #networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Kyiv";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "uk_UA.UTF-8";
    LC_IDENTIFICATION = "uk_UA.UTF-8";
    LC_MEASUREMENT = "uk_UA.UTF-8";
    LC_MONETARY = "uk_UA.UTF-8";
    LC_NAME = "uk_UA.UTF-8";
    LC_NUMERIC = "uk_UA.UTF-8";
    LC_PAPER = "uk_UA.UTF-8";
    LC_TELEPHONE = "uk_UA.UTF-8";
    LC_TIME = "uk_UA.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services = {
    desktopManager.plasma6 = {
      enable = true;
      enableQt5Integration = true; # disable for qt6 full version
    };
    displayManager = {
      defaultSession = "plasma";
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    };
  };
  # services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = false;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # systemd.services.fprintd = {
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig.Type = "simple";
  # };

  # services.fprintd.enable = true;
  # services.fprintd.tod.enable = true;
  # services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;

  services.ollama = {
    enable = true;
    acceleration = "rocm";
    loadModels = [
      "gemma3"
    ];
  };

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

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
  #
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

  # Install firefox.
  programs.firefox.enable = true;

  # Steam
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  nixpkgs.config = {
    allowUnfree = true;
  };
  programs.nix-ld.enable = true;
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    dotnetCorePackages.sdk_9_0
    telegram-desktop
    nix-output-monitor # nom. for build logs

    lazygit
    git

    #tools
    nettools
    usbutils

    yazi
    fzf
    zoxide
    dblab

    blackbox-terminal
  ];
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
