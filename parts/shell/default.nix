{
  inputs,
  config,
  lib,
  pkgs,
  users,
  ...
}:

{
  options = {
    batat.shell.enable = lib.mkEnableOption "enables shell (zsh and plugins)";
  };

  config = lib.mkIf config.batat.shell.enable {

    environment.systemPackages =
      with pkgs;
      [
        pay-respects
        eza # ls alternative
        oh-my-posh
      ]
      ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

    programs.zsh = {
      enable = true;

      shellAliases = {
        batat-test-c = "sudo echo -e '\\c';sudo nixos-rebuild test --option eval-cache false --flake $HOME/.dotfiles/ |& nom";
        batat-test = "sudo echo -e '\\c';sudo nixos-rebuild test --flake $HOME/.dotfiles/ |& nom";
        batat-test-pc = "sudo echo -e '\\c';sudo nixos-rebuild test --flake $HOME/.dotfiles/#pc |& nom";
        batat-test-nout = "sudo echo -e '\\c';sudo nixos-rebuild test --flake $HOME/.dotfiles/#lenovo |& nom";
        batat-roll = "sudo echo -e '\\c';sudo nixos-rebuild switch --flake $HOME/.dotfiles/ |& nom";
        batat-roll-pc = "sudo echo -e '\\c';sudo nixos-rebuild switch --flake $HOME/.dotfiles/#pc |& nom";
        batat-roll-nout = "sudo echo -e '\\c';sudo nixos-rebuild switch --flake $HOME/.dotfiles/#lenovo |& nom";
        batat-edit = "cd $HOME/.dotfiles/ && nvim .";
        batat-gc = "nix-collect-garbage --delete-older-than 7d";
        batat-upd = "nix flake update --flake $HOME/.dotfiles/";
        batat-list = "nix-env --list-generations";
        grep = "grep --color=auto";

        ls = "eza";
        cd = "z";

        nz = "nix-shell --command zsh";
        # zenv = "nix-shell --command zsh \"$HOME/.dotfiles/envs/$1/\""; todo create bash functions that handle such cases

        ssh-init = "eval $(ssh-agent -s) && ssh-add";

        v = "nvim";
      };

      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;

      # history
      histFile = "$HOME/.config/zsh_history";
      setOptions = [ "INC_APPEND_HISTORY" ];

      ohMyZsh = {
        enable = true;
        plugins = [
          "pay-respects"
          "eza"
          "fzf"
          "sudo" # press escape twice to sudo
          "aliases" # als - show all aliases
          "git"
          # aliases for git commit with prefixes
          # use git fix -s "api" "message"
          # git feat "message"
          "git-commit"
          "rust"
          # "colorize" todo i think bat is a viable alternative
          "extract" # get files from archives
        ];
        theme = "robbyrussell";
      };
      promptInit = ''
        eval "$(zoxide init zsh)"
      '';

    };

    home-manager.users.askold = {
      programs.zsh.initContent = "source ${./zshrc.sh}";
      programs.zsh.autocd = true;
    };

    users.defaultUserShell = pkgs.zsh;
    users.users.askold.shell = pkgs.zsh;
  };
}
