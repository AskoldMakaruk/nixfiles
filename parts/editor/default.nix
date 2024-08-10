{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  options = {
    batat.editor.enable = lib.mkEnableOption "enables editors";
  };

  config = lib.mkIf config.batat.editor.enable {
    home-manager.users.askold = {
      programs.neovim = {
        enable = true;
        plugins = with pkgs.vimPlugins; [

          LazyVim # distro

          nvim-web-devicons # icons
          lightline-vim # status line
          vim-cool # don't highlight search results
          which-key-nvim # hints?

          trouble-nvim # errors window
          # v/V to select region
          vim-expand-region

          # fuzzy search
          telescope-fzf-native-nvim
          telescope-nvim

          # intellisense
          nvim-cmp # engine

          # sources
          cmp-zsh
          cmp-buffer
          cmp-path
          cmp-nvim-lua
          cmp-nvim-lsp
          cmp-nvim-lsp-signature-help
          nvim-lspconfig # lsp

          none-ls-nvim # formating diagnostincs
          conform-nvim

          gitsigns-nvim
          neo-tree-nvim
          nvim-lint
          nvim-lspconfig
          nvim-spectre

          nvim-treesitter
          nvim-treesitter.withAllGrammars
          nvim-treesitter-context
          nvim-treesitter-textobjects
          nvim-comment # gcc

          nvim-surround
          vim-textobj-user
          vim-textobj-entire
          vim-closer

          persistence-nvim
          todo-comments-nvim
          vim-illuminate

          lazygit-nvim

          obsidian-nvim
          # knap # live file preview

          rustaceanvim
          rust-vim
          rust-tools-nvim

          vim-ledger
        ];

        # .vimrc
        #        extraConfig = ''
        #         :luafile ~/.config/nvim/lua/init.lua
        #      '';
      };
      home.packages = with pkgs; [
        rust-analyzer
        rustfmt

        stylua
        ripgrep
        lazygit
        fd

        cmake
        gcc
        luarocks

        wl-clipboard

        tree-sitter
        shfmt # shell formatter
        lua-language-server
        ledger

        nixfmt-rfc-style # todo later rename nixfmt
      ];

      ## copying config 
      ## todo investigate difference between xdg and home
      ## may cause troubles 
      home.file = {
        ".config" = {
          source = ./config;
          recursive = true;
        };
      };

      #   xdg.configFile."nvim" = {
      #     source = ./config;
      #     recursive = true;
      #   };
    };
  };
}
