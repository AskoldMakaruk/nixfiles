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
    # /kilocode — ro, agent configs + secrets + skills from dotfiles repo
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
      {
        tag = "kilocode";
        mountPoint = "/kilocode";
        proto = "virtiofs";
        source = "/var/lib/ai-sandbox/kilocode";
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
    ])
    ++ [
      # AI agent (pre-built binary from official releases)
      kilocode-pkg
    ];

  # Nix inside VM (for nix-shell, devshells)
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # ── Age secrets ────────────────────────────────────────────────────────────────
  # API keys for Kilo Code agent (Anthropic, OpenAI, etc.)
  # Encrypted file lives in ~/secrets/kilocode-api-keys.age (private repo)
  # Create with:
  #   age -e -r $(cat ~/.ssh/agenix_key.pub) -o ~/secrets/kilocode-api-keys.age secrets.json
  age = {
    identityPaths = [ "/home/agent/.ssh/agenix_key" ];
    secrets = {
      kilocode-secrets = {
        file = inputs.mysecrets + "/kilocode-api-keys.age";
        owner = "agent";
        group = "users";
        mode = "0400";
      };
    };
  };

  # ── KiloCode dir assembly ────────────────────────────────────────────────────
  # Assemble /home/agent/.kilocode from:
  #   - /kilocode           (virtiofs ro from dotfiles — cli configs, skills)
  #   - /run/agenix/kilocode-secrets  (agenix — API keys)
  #
  # Mutable parts (history, logs, workspaces) are created in agent's home.

  systemd.services.agent-kilocode-setup = {
    description = "Assemble agent .kilocode directory from dotfiles + secrets";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    requires = [ "agenix.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      KC=/home/agent/.kilocode
      mkdir -p "$KC"

      # ── CLI configs (ro) ─────────────────────────────────────────────────
      mkdir -p "$KC/cli/global/settings"
      cp -rn /kilocode/cli/config.json "$KC/cli/config.json" 2>/dev/null || true
      cp -rn /kilocode/cli/global/settings/custom_modes.yaml "$KC/cli/global/settings/" 2>/dev/null || true
      cp -rn /kilocode/cli/global/settings/mcp_settings.json "$KC/cli/global/settings/" 2>/dev/null || true

      # ── Secrets (from agenix) ────────────────────────────────────────────
      if [ -f /run/agenix/kilocode-secrets ]; then
        cp /run/agenix/kilocode-secrets "$KC/secrets.json"
      fi

      # ── Skills (ro symlink) ──────────────────────────────────────────────
      ln -sfn /kilocode/skills "$KC/skills"

      # ── Mutable dirs ─────────────────────────────────────────────────────
      mkdir -p "$KC/cli/logs"
      mkdir -p "$KC/cli/workspaces"

      # ── Ownership ────────────────────────────────────────────────────────
      chown -R agent:users "$KC"
    '';
  };

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
