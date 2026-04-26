{
  config,
  lib,
  pkgs,
  pkgs-askold,
  pkgs-master,
  graphify,
  kilocode-pkg,
  ...
}:
{
  options = {
    batat.programs.enable = lib.mkEnableOption "enables basic programs";
  };

  config = lib.mkIf config.batat.programs.enable {

    environment.systemPackages = with pkgs; [
      anki-bin

      # (pkgs-master.godot-mono.override { dotnet-sdk = pkgs-master.dotnet-sdk_10; })
      # pkgs-askold.godot-mono

      # deprecated due to electron 35 dependency
      # affine # mira alternative; collaborative whiteboard & markdown database

      telegram-desktop

      simplex-chat-desktop

      # voip chat
      mumble

      # notebook
      nb

      lorien # minimalistic infinite canvas

      vlc

      #     ghostty # terminal emulator

      folo
      #openssl_legacy

      # Tag Studio
      # UI for managing files marked by tags
      # written in python by youtuber, weights 2GB
      # inputs.tagstudio.packages.${pkgs.stdenv.hostPlatform.system}.tagstudio
      #

      pkgs-master.beets
      # humanity has fallen
      pkgs-master.claude-code
      pkgs-master.ollama
      # AI coding agent (pre-built binary from official releases)
      kilocode-pkg
      python3 # ai loves little python shitptss

      # two factor auth
      kdePackages.keysmith

      # vpns
      openfortivpn
      gof5

      # work browser
      ungoogled-chromium
    ];

    programs.firefox.enable = true;

    services.qdrant = {
      enable = true;
      package = pkgs-master.qdrant;
      webUIPackage = pkgs-master.qdrant-web-ui;

      settings = {
        storage = {
          storage_path = "/var/lib/qdrant/storage";
          snapshots_path = "/var/lib/qdrant/snapshots";
        };
        hsnw_index = {
          on_disk = true;
        };
        service = {
          host = "127.0.0.1";
          http_port = 6333;
          grpc_port = 6334;
        };
        telemetry_disabled = false;
      };
    };

  };
}
