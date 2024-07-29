{ inputs, config, lib, pkgs, ...}:

{
options = {
  batat.console.enable =
    lib.mkEnableOption "enables console modules";
  };

  config = lib.mkIf config.batat.console.enable {

   environment.systemPackages = with pkgs; [
      zsh
      tilda
  ];

    programs.zsh = {
      enable = true;

      shellAliases = {
        batat-upd = "sudo echo -e '\\c';sudo nixos-rebuild switch --flake $HOME/.dotfiles/flake.nix |& nom";
        batat-edit = "nvim $HOME/.dotfiles/flake.nix";
        batat-gc = "nix-collect-garbage --delete-older-than 7d";
        grep = "grep --color=auto";
      };
      autosuggestions.enable = true;
      histFile = "$HOME/.config/zsh_history";

      setOptions = [ "INC_APPEND_HISTORY"];

      syntaxHighlighting.enable = true;

   };
   users.defaultUserShell = pkgs.zsh;
  };
}
