{
  config,
  lib,
  pkgs,
  ...
}:

{
  options = {
    batat.nvim.enable = lib.mkEnableOption "enables nvim";
  };

  config = lib.mkIf config.batat.nvim.enable {
    home-manager.users.askold = {

      ## NEOVIM
      programs.neovim = {
        enable = true;
        coc.enable = true;
      };

      home.packages = with pkgs; [

        # fsautocomplete # built with deprecated dotnet version

        stylua
        ripgrep
        lazygit
        fd

        cmake
        gcc
        luarocks

        wl-clipboard
        xclip

        tree-sitter
        shfmt # shell formatter
        lua-language-server
        ledger
        # csharp formatter
        csharpier
        # netcore managed debugger
        netcoredbg

        roslyn-ls
        #       omnisharp-roslyn

        # nix language server
        nil

        # nix formatter
        nixfmt-rfc-style

        nixfmt-rfc-style # todo later rename nixfmt
      ];

      ## copying config
      home.file = {
        ".config/nvim" = {
          source = ./config/nvim;
          recursive = true;
        };
      };
    };
  };
}
