{ inputs, config, lib, pkgs, ...}:

{
options = {
  batat.console.enable =
    lib.mkEnableOption "enables console modules";
  };

  config = lib.mkIf config.batat.console.enable {
    programs.zsh = {
      enable = true;

      shellAliases = {
        batat-upd = "sudo echo -e '\\c';sudo nixos-rebuild switch --flake $HOME/.dotfiles/flake.nix |& nom";
        batat-edit = "nvim $HOME/.dotfiles/flake.nix"
        batat-gc = "nix-collect-garbage --delete-older-than 7d"
        grep = "grep --color=auto"
      };
      autosuggestions.enable = true;
      histFIle = "$HOME/.config/zsh_history";

      setOptions = [ "INC_APPEND_HISTORY"];

      syntaxHighlihting.enable = true;

      users.defaultUserShell = pkgs.zsh;
   }
  }
}
