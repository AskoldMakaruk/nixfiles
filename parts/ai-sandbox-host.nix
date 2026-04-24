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

    # ── microvm host ──────────────────────────────────────────────────────────

    microvm.vms.ai-sandbox = {
      flake = self;
    };

    # ── Bridge + NAT ──────────────────────────────────────────────────────────

    networking.bridges.br-ai.interfaces = [ ]; # tap added dynamically via udev

    networking.interfaces.br-ai.ipv4.addresses = [
      {
        address = "10.100.0.1";
        prefixLength = 24;
      }
    ];

    networking.nat = {
      enable = true;
      internalInterfaces = [ "br-ai" ];
      externalInterface = cfg.externalInterface;
    };

    # Add tap to bridge when microvm creates it
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", KERNEL=="ai-tap0", \
        RUN+="${pkgs.iproute2}/bin/ip link set %k master br-ai up"
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

          echo "→ mounting workspace: $WORKSPACE"
          sudo mount --bind "$WORKSPACE" /var/lib/ai-sandbox/workspace

          if [ -n "$CONTEXT" ]; then
            echo "→ mounting context: $CONTEXT"
            sudo mount --bind -o ro "$CONTEXT" /var/lib/ai-sandbox/context
          fi

          trap '
            echo "→ unmounting..."
            sudo umount /var/lib/ai-sandbox/workspace 2>/dev/null || true
            sudo umount /var/lib/ai-sandbox/context 2>/dev/null || true
          ' EXIT

          echo "→ starting VM..."
          sudo systemctl start microvm@ai-sandbox

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
        '';
      in
      [
        start
        stop
      ];
  };
}
