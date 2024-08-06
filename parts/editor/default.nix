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
    home-manager.users."askold" = {
      programs.neovim = {
        enable = true;
        plugins = with pkgs.vimPlugins; [

          LazyVim # distro

          nvim-web-devicons # icons
          lightline-vim # status line
          vim-cool # don't highlight search results
          which-key-nvim # hints?

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
          trouble-nvim
          vim-illuminate

          lazygit-nvim

          obsidian-nvim
          # knap # live file preview

          rustaceanvim
          rust-vim
          rust-tools-nvim
        ];

        extraConfig = ''
          :luafile ~/.config/nvim/lua/init.lua
        '';
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

        nixfmt-rfc-style # todo later rename nixfmt
      ];

      xdg.configFile.nvim = {
        source = ./config;
        recursive = true;
      };
    };

    #    programs.neovim = {
    #      enable = true;

    #      colorschemes.gruvbox.enable = true;
    #      plugins.lightline.enable = true;
    #
    #      extraPlugins = with pkgs.vimPlugins; [
    #        lazy-nvim
    #        rust-vim
    #      ];
    #
    #      extraConfigLua =
    #        let
    #          plugins = with pkgs.vimPlugins; [
    #          ];
    #          mkEntryFromDrv =
    #            drv:
    #            if lib.isDerivation drv then
    #              {
    #                name = "${lib.getName drv}";
    #                path = drv;
    #              }
    #            else
    #              drv;
    #          lazyPath = pkgs.linkFarm "lazy-plugins" (builtins.map mkEntryFromDrv plugins);
    #        in
    #        ''
    #                require("lazy").setup({
    #          	defaults = {
    #          	lazy = true,
    #                },
    #                dev = {
    #                  path = "${lazyPath}",
    #          	patters = { "." },
    #          	fallback = true
    #                },
    #                spec = {
    #                  { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    #          	{ "nvim-telescope/telescope-fzf-native.nvim", enabled = true },
    #          	-- disable mason plugin manager because plugins are managed by nix
    #          	{ "williamboman/mason-lspconfig.nvim", enabled = false },
    #          	{ "williamboman/mason.nvim", enabled = false },
    #          	-- import plugins
    #          	{ import = "plugins" },
    #          	-- treesitter config
    #          	{ "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = {"rust"} } },
    #                },
    #                })
    #        '';
    #      plugins.conform-nvim.enable = true;
    #      plugins.conform-nvim.formattersByFt = {
    #        rust = [ "rustfmt" ];
    #        nix = [ "nixfmt" ];
    #      };
    #    };
  };
}

#};

# https://github.com/nvim-treesitter/nvim-treesitter#i-get-query-error-invalid-node-type-at-position
#xdg.configFile."nvim/parser".source =
#  let
#    parsers = pkgs.symlinkJoin {
#      name = "treesitter-parsers";
#      paths = (pkgs.vimPlugins.nvim-treesitter.withPlugins (plugins: with plugins; [
#        c
#        lua
#      ])).dependencies;
#    };
#  in
#  "${parsers}/parser";

# Normal LazyVim config here, see https://github.com/LazyVim/starter/tree/main/lua
# xdg.configFile."nvim/lua".source = ./lua;
