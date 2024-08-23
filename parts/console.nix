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
    batat.console.enable = lib.mkEnableOption "enables console modules";
  };

  config = lib.mkIf config.batat.console.enable {

    environment.systemPackages = with pkgs; [
      zsh
      tilda
      nerdfonts
      thefuck

      # ls alternative
      eza

      # syntax highlighter for colorize plugin
      # chroma

      # hitchhiker
      fortune
      # strfile
      neo-cowsay

      oh-my-posh
    ];

    programs.zsh = {
      enable = true;

      shellAliases = {
        batat-test-c = "sudo echo -e '\\c';sudo nixos-rebuild test --option eval-cache false --flake $HOME/.dotfiles/ |& nom";
        batat-test = "sudo echo -e '\\c';sudo nixos-rebuild test --flake $HOME/.dotfiles/ |& nom";
        batat-roll = "sudo echo -e '\\c';sudo nixos-rebuild switch --flake $HOME/.dotfiles/ |& nom";
        batat-edit = "cd $HOME/.dotfiles/ && nvim .";
        batat-gc = "nix-collect-garbage --delete-older-than 7d";
        grep = "grep --color=auto";

        nz = "nix-shell --command zsh";
        zenv = ''nix-shell --command zsh $HOME/.dotfiles/envs/"$1"/'';

        v = "nvim";
        wb = "web-search";

        hh = "hitchhiker";
        hhc = "hitchhiker_cow";
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
          "thefuck"
          "eza"
          "fzf"
          "sudo" # press escape twice to sudo
          "aliases" # als - show all aliases
          "git"
          # aliases for git commit with prefixes
          # use git fix -s "api" "message"
          # git feat "message"
          "git-commit"
          # <context> <query> where context is google youtube github or other search engine
          "web-search"

          "rust"

          # "colorize" todo i think bat is a viable alternative
          "theme" # change zsh theme

          "extract" # get files from archives
          "hitchhiker" # hh hhc
          "oh-my-posh"
        ];
        theme = "robbyrussell";
      };

    };


    users.defaultUserShell = pkgs.zsh;
    users.users.askold.shell = pkgs.zsh;
  };
}
