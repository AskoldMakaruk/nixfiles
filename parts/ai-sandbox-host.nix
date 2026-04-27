# Host-side config for the ai-sandbox microvm.
# Import this in hosts/lenovo/configuration.nix (or pc) to enable.
#
# Usage:
#   start-ai-sandbox /path/to/repo [/path/to/context]
#   ssh agent@10.100.0.2
#   stop-ai-sandbox

{
  config,
  pkgs,
  lib,
  self,
  inputs,
  ...
}:
let
  cfg = config.batat.aiSandbox;
in
{
  imports = [ inputs.microvm.nixosModules.host ];

  options.batat.aiSandbox = {
    enable = lib.mkEnableOption "ai-sandbox microvm";
  };

  config = lib.mkIf cfg.enable {

    # Disable host firewall — the machine is behind a router NAT anyway,
    # and it interferes with forwarding traffic from the microvm.
    networking.firewall.enable = false;

    # ── microvm host ──────────────────────────────────────────────────────────

    microvm.vms.ai-sandbox = {
      flake = self;
    };

    # ── Bridge + NAT ──────────────────────────────────────────────────────────
    # Uses scripted networking (networking.bridges + udev) so it doesn't conflict
    # with the host's existing dhcpcd-managed wifi/ethernet interfaces.

    networking.bridges.br-ai.interfaces = [ ];

    networking.interfaces.br-ai.ipv4.addresses = [
      {
        address = "10.100.0.1";
        prefixLength = 24;
      }
    ];

    # Auto-attach tap interface to bridge when microvm creates it
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", KERNEL=="ai-tap0", \
        RUN+="${pkgs.iproute2}/bin/ip link set %k master br-ai up"
    '';

    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    # Masquerade all traffic from the microvm bridge
    networking.nftables.enable = true;
    networking.nftables.ruleset = ''
      table ip batat-nat {
        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          ip saddr 10.100.0.0/24 oifname != "br-ai" masquerade
        }
      }
    '';

    # ── Bind-mount dirs ───────────────────────────────────────────────────────

    systemd.tmpfiles.rules = [
      "d /var/lib/ai-sandbox 0755 root root"
      "d /var/lib/ai-sandbox/workspace 0755 root root"
      "d /var/lib/ai-sandbox/context 0755 root root"
    ];

    # ── start/stop scripts ────────────────────────────────────────────────────

    environment.systemPackages =
      let
        start = pkgs.writeShellScriptBin "start-ai-sandbox" ''
          set -euo pipefail

          WORKSPACE="''${1:-}"
          CONTEXT="''${2:-}"

          if [ -z "$WORKSPACE" ]; then
            echo "Usage: start-ai-sandbox <repo-path> [context-path]"
            exit 1
          fi

          if mountpoint -q /var/lib/ai-sandbox/workspace; then
            echo "→ workspace already mounted, skipping"
          else
            echo "→ mounting workspace: $WORKSPACE"
            sudo mount --bind "$WORKSPACE" /var/lib/ai-sandbox/workspace
          fi

          if [ -n "$CONTEXT" ]; then
            if mountpoint -q /var/lib/ai-sandbox/context; then
              echo "→ context already mounted, skipping"
            else
              echo "→ mounting context: $CONTEXT"
              sudo mount --bind -o ro "$CONTEXT" /var/lib/ai-sandbox/context
            fi
          fi

          trap '
            echo "→ stopping VM..."
            sudo systemctl stop microvm@ai-sandbox 2>/dev/null || true
            echo "→ unmounting..."
            sudo umount /var/lib/ai-sandbox/workspace 2>/dev/null || true
            sudo umount /var/lib/ai-sandbox/context 2>/dev/null || true
          ' EXIT

          echo "→ (re)starting VM..."
          sudo systemctl restart microvm@ai-sandbox

          echo ""
          echo "VM running. SSH in:"
          echo "  ssh agent@10.100.0.2"
          echo ""
          echo "Press Ctrl-C to stop VM and unmount."
          # Wait until killed
          tail -f /dev/null
        '';

        stop = pkgs.writeShellScriptBin "stop-ai-sandbox" ''
          set -euo pipefail
          echo "→ stopping VM..."
          sudo systemctl stop microvm@ai-sandbox
          echo "→ unmounting..."
          sudo umount /var/lib/ai-sandbox/workspace 2>/dev/null || true
          sudo umount /var/lib/ai-sandbox/context 2>/dev/null || true
          echo "done."
          # kilocode mount is managed by systemd, no manual unmount needed
        '';
      in
      [
        start
        stop
      ];
  };
}
