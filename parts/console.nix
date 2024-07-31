{ inputs, config, lib, pkgs, users, ...}:

{
options = {
  batat.console.enable =
    lib.mkEnableOption "enables console modules";
  };

  config = lib.mkIf config.batat.console.enable {

   environment.systemPackages = with pkgs; [
      zsh
      tilda
      nerdfonts
  ];

    programs.zsh = {
      enable = true;

      shellAliases = {
        batat-test-c = "sudo echo -e '\\c';sudo nixos-rebuild test --option eval-cache false --flake $HOME/.dotfiles/ |& nom";
        batat-test = "sudo echo -e '\\c';sudo nixos-rebuild test --flake $HOME/.dotfiles/ |& nom";
        batat-roll = "sudo echo -e '\\c';sudo nixos-rebuild switch --flake $HOME/.dotfiles/ |& nom";
        batat-edit = "nvim $HOME/.dotfiles/flake.nix";
        batat-gc = "nix-collect-garbage --delete-older-than 7d";
        grep = "grep --color=auto";

	      v = "nvim";
      };
      autosuggestions.enable = true;
      histFile = "$HOME/.config/zsh_history";

      setOptions = [ "INC_APPEND_HISTORY"];

      syntaxHighlighting.enable = true;

   };
   users.defaultUserShell = pkgs.zsh;
   users.users.askold.shell = pkgs.zsh;
  };
}
