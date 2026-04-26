# Host-side config for the ai-sandbox microvm.
# Import this in hosts/lenovo/configuration.nix (or pc) to enable.
#
# After importing, set your external network interface:
#   batat.aiSandbox.externalInterface = "wlp3s0";  # or "enp2s0", etc.
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

    externalInterface = lib.mkOption {
      type = lib.types.str;
      description = "Host network interface for NAT (e.g. wlp3s0, enp2s0)";
      example = "wlp3s0";
    };
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
    # Refactored to systemd-networkd + networking.nat (blog post pattern)

    systemd.network.enable = true;

    systemd.network.netdevs."20-br-ai" = {
      netdevConfig = {
        Kind = "bridge";
        Name = "br-ai";
      };
    };

    systemd.network.networks."20-br-ai" = {
      matchConfig.Name = "br-ai";
      addresses = [ { Address = "10.100.0.1/24"; } ];
      networkConfig.ConfigureWithoutCarrier = true;
    };

    # Auto-attach any ai-tap* interface to the bridge
    systemd.network.networks."21-ai-tap" = {
      matchConfig.Name = "ai-tap*";
      networkConfig.Bridge = "br-ai";
    };

    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    networking.nat = {
      enable = true;
      internalInterfaces = [ "br-ai" ];
      externalInterface = cfg.externalInterface;
    };

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
