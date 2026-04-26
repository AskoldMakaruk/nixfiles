{
  config,
  pkgs,
  lib,
  inputs,
  kilocode-pkg,
  ...
}:
let
  pkgs-master = import inputs.nixpkgs-master {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
in
{
  microvm = {
    hypervisor = "qemu";

    mem = 4096;
    vcpu = 4;

    # ── Store disk flags ────────────────────────────────────────────────
    # Default -zlz4hc is 10-50x slower than -zlz4 and -Efragments/-Ededupe
    # disable multi-threading. Using plain lz4 + tailpacking only keeps the
    # build fast (parallel) while still getting good enough compression.
    storeDiskErofsFlags = [
      "-zlz4" # fast LZ4, not HC — HC is extremely slow
      "-Eztailpacking" # tail packing — fast, doesn't block threading
    ];

    # Persistent home for agent (npm/nuget caches, claude config, etc.)
    volumes = [
      {
        mountPoint = "/home/agent";
        image = "agent-home.img";
        size = 20480; # 20 GB
      }
    ];

    # /workspace — rw, the active repo (bind-mounted by start-ai-sandbox script)
    # /context   — ro, docs/notes passed as context
    # /home/agent/.local/share/kilo — rw, host's kilodata dir mounted directly
    shares = [
      {
        tag = "workspace";
        mountPoint = "/home/agent/workspace";
        proto = "virtiofs";
        source = "/var/lib/ai-sandbox/workspace";
      }
      {
        tag = "context";
        mountPoint = "/context";
        proto = "virtiofs";
        source = "/var/lib/ai-sandbox/context";
      }
      {
        tag = "kilo";
        mountPoint = "/home/agent/.local/share/kilo";
        proto = "virtiofs";
        source = "/home/askold/.local/share/kilo";
      }
    ];

    interfaces = [
      {
        type = "tap";
        id = "ai-tap0";
        mac = "02:00:00:aa:00:01";
      }
    ];
  };

  networking = {
    hostName = "ai-sandbox";
    useDHCP = false;
    useNetworkd = true;
    usePredictableInterfaceNames = false;
    nameservers = [
      "8.8.8.8"
      "1.1.1.1"
    ];

    # Whitelist outbound: DNS + HTTPS/HTTP + SSH (git over ssh)
    nftables.enable = true;
    nftables.ruleset = ''
      table inet filter {
        chain input {
          type filter hook input priority 0; policy drop;

          ct state { established, related } accept
          iif "lo" accept

          # SSH only from host LAN
          ip saddr 10.100.0.0/24 tcp dport 22 accept
        }

        chain forward {
          type filter hook forward priority 0; policy drop;
        }

        chain output {
          type filter hook output priority 0; policy accept;
        }
      }
    '';
  };

  systemd.network.enable = true;
  systemd.network.networks."10-e" = {
    matchConfig.Name = "e*";
    addresses = [ { Address = "10.100.0.2/24"; } ];
    routes = [ { Gateway = "10.100.0.1"; } ];
  };

  programs = {
    nix-ld.enable = true;
  };

  # Ensure parent dirs exist for the kilo virtiofs mount
  systemd.tmpfiles.rules = [
    "d /home/agent/.local 0755 agent users"
    "d /home/agent/.local/share 0755 agent users"
  ];

  environment.systemPackages =
    (with pkgs; [
      git
      curl
      wget
      ripgrep
      fd
      jq
      tree
      unzip
      nodejs
      nodePackages.npm

      yazi
      fzf
      zoxide
      dblab
      comma # , to call bins from nixpkgs

      # websocket cli client
      claws

      ghostty

      systemctl-tui

    ])
    ++ (with pkgs-master; [
      dotnetCorePackages.sdk_10_0

      # Cloudflare challenge bypass
      curl-impersonate
      curl-impersonate-chrome
      chromium
      undetected-chromedriver
      flaresolverr
    ])
    ++ [
      (pkgs.python3.withPackages (ps: [
        ps.cloudscraper
        ps.cfscrape
        ps.undetected-chromedriver
        ps.playwright
        ps.playwright-stealth
      ]))
      kilocode-pkg
    ];

  # Nix inside VM (for nix-shell, devshells)
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Kilodata is mounted directly from host at /home/agent/.local/share/kilo

  # ── SSH ──────────────────────────────────────────────────────────────────────

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # ── Agent user ───────────────────────────────────────────────────────────────

  users.users.agent = {
    isNormalUser = true;
    createHome = true;
    home = "/home/agent";
    extraGroups = [ "wheel" ];

    openssh.authorizedKeys.keys = [
      # Host user keys — add yours here or import from secrets
      # lenovo / office machine
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKHio8WbNZzw9q6G/GjMvhhsxe93+q9v0P+0ecdDft8c officekiev\\a.makaruk@N-KV-BOR35O-015"
      # pc-machine
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAG+yaR+V4osEzcipG2R2Tdmu7ZWswe4IZNpaXNOkzTu askold@nixos"
    ];
  };

  # passwordless sudo for agent (inside isolated VM, acceptable)
  security.sudo.extraRules = [
    {
      users = [ "agent" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  system.stateVersion = "25.11";
}
