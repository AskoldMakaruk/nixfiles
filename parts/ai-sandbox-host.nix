# Host-side config for the ai-sandbox system user.
# Import this in hosts/lenovo/configuration.nix (or pc) to enable.
#
# The ai-sandbox is a separate system user (agent) with its own home directory
# at /home/agent. All tools are installed as system packages so the agent can
# use them directly on the host.
#
# Usage:
#   start-ai-sandbox [/path/to/repo]
#     → mounts repo to /home/agent/workspace, drops into agent shell
#   stop-ai-sandbox
#     → unmounts workspace

{
  config,
  pkgs,
  lib,
  pkgs-master,
  kilocode-pkg,
  ...
}:
let
  cfg = config.batat.aiSandbox;

  start = pkgs.writeShellScriptBin "start-ai-sandbox" ''
    set -euo pipefail

    WORKSPACE="''${1:-}"

    cleanup() {
      echo "→ unmounting workspace..."
      sudo umount /home/agent/workspace 2>/dev/null || true
    }

    if [ -n "$WORKSPACE" ]; then
      if mountpoint -q /home/agent/workspace 2>/dev/null; then
        echo "→ workspace already mounted, skipping"
      else
        echo "→ mounting workspace: $WORKSPACE"
        sudo mkdir -p /home/agent/workspace
        sudo mount --bind "$WORKSPACE" /home/agent/workspace
      fi
    fi

    trap cleanup EXIT

    echo "→ dropping into agent shell..."
    echo "  (type exit or Ctrl-D to return)"
    echo ""

    if mountpoint -q /home/agent/workspace 2>/dev/null; then
      sudo -u agent -i bash -c 'cd /home/agent/workspace && exec $SHELL'
    else
      sudo -u agent -i
    fi
  '';

  stop = pkgs.writeShellScriptBin "stop-ai-sandbox" ''
    set -euo pipefail
    echo "→ unmounting workspace..."
    sudo umount /home/agent/workspace 2>/dev/null || true
    echo "done."
  '';
in
{
  options.batat.aiSandbox = {
    enable = lib.mkEnableOption "ai-sandbox system user";
  };

  config = lib.mkIf cfg.enable {

    users.users.agent = {
      isNormalUser = true;
      createHome = true;
      home = "/home/agent";
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKHio8WbNZzw9q6G/GjMvhhsxe93+q9v0P+0ecdDft8c officekiev\\a.makaruk@N-KV-BOR35O-015"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAG+yaR+V4osEzcipG2R2Tdmu7ZWswe4IZNpaXNOkzTu askold@nixos"
      ];
    };

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
        comma
        claws
        ghostty
        systemctl-tui
      ])
      ++ (with pkgs-master; [
        dotnetCorePackages.sdk_10_0
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
        start
        stop
      ];
  };
}
