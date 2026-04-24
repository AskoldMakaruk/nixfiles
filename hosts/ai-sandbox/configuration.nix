{
  config,
  pkgs,
  lib,
  inputs,
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
    shares = [
      {
        tag = "workspace";
        mountPoint = "/workspace";
        proto = "virtiofs";
        source = "/var/lib/ai-sandbox/workspace";
      }
      {
        tag = "context";
        mountPoint = "/context";
        proto = "virtiofs";
        source = "/var/lib/ai-sandbox/context";
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

  # ── Networking ──────────────────────────────────────────────────────────────

  networking = {
    hostName = "ai-sandbox";
    usePredictableInterfaceNames = false;

    interfaces.eth0.ipv4.addresses = [
      {
        address = "10.100.0.2";
        prefixLength = 24;
      }
    ];
    defaultGateway = {
      address = "10.100.0.1";
      interface = "eth0";
    };
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];

    # Whitelist outbound: DNS + HTTPS/HTTP + SSH (git over ssh)
    # Blocks everything else — no lateral movement, no arbitrary exfil
    # For stricter control, replace tcp dport {80,443} with explicit IP sets
    nftables.enable = true;
    nftables.ruleset = ''
      table inet filter {
        chain input {
          type filter hook input priority 0; policy drop;

          ct state { established, related } accept
          iif "lo" accept

          # SSH only from host LAN
          ip saddr 10.100.0.0/24 tcp dport 22 accept

          icmp type echo-request accept
          icmpv6 type echo-request accept
        }

        chain forward {
          type filter hook forward priority 0; policy drop;
        }

        chain output {
          type filter hook output priority 0; policy drop;

          ct state { established, related } accept
          oif "lo" accept

          # DNS
          udp dport 53 accept
          tcp dport 53 accept

          # HTTPS — NuGet, npm, GitHub, Anthropic API, Nix cache
          tcp dport { 80, 443 } accept

          # SSH out — git over SSH (github, etc.)
          tcp dport 22 accept

          icmp type echo-request accept
          icmpv6 type echo-request accept
        }
      }
    '';
  };

  # ── Packages ─────────────────────────────────────────────────────────────────

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
      # JS/Svelte toolchain
      nodejs
      nodePackages.npm
    ])
    ++ (with pkgs-master; [
      # C# toolchain
      dotnetCorePackages.sdk_10_0
      # AI agent
      kilocode-cli
    ]);

  # Nix inside VM (for nix-shell, devshells)
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

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
      # Host user key — add yours here or import from secrets
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKHio8WbNZzw9q6G/GjMvhhsxe93+q9v0P+0ecdDft8c officekiev\\a.makaruk@N-KV-BOR35O-015"
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
