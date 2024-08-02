{ inputs, config, lib, pkgs, ... }:

{
  options = { batat.editor.enable = lib.mkEnableOption "enables editors"; };

  config = lib.mkIf config.batat.editor.enable {

    programs.nixvim = {
      enable = true;
      extraPackages = with pkgs; [
        luarocks
        lua-language-server
        stylua
        ripgrep
        lazygit
        fd
        cmake
        gcc
        shfmt # shell formatter

        rust-analyzer
        tree-sitter
      ];

      colorschemes.gruvbox.enable = true;
      plugins.lightline.enable = true;

      extraPlugins = [ pkgs.vimPlugins.lazy-nvim ];

      extraConfigLua = let
        plugins = with pkgs.vimPlugins; [
          LazyVim
          cmp-buffer
          # cmp-nvim-lsp
          # cmp-path
          conform-nvim
          gitsigns-nvim
          neo-tree-nvim
          nvim-lint
          nvim-lspconfig
          nvim-spectre
          nvim-treesitter
          nvim-treesitter-context
          nvim-treesitter-textobjects
          nvim-web-devicons
          persistence-nvim
          telescope-fzf-native-nvim
          telescope-nvim
          todo-comments-nvim
          trouble-nvim
          vim-illuminate
          which-key-nvim

          lazygit-nvim

          obsidian-nvim
        ];
        mkEntryFromDrv = drv:
          if lib.isDerivation drv then {
            name = "${lib.getName drv}";
            path = drv;
          } else
            drv;
        lazyPath =
          pkgs.linkFarm "lazy-plugins" (builtins.map mkEntryFromDrv plugins);
      in ''
              require("lazy").setup({
        	defaults = {
        	lazy = true,
              },
              dev = {
                path = "${lazyPath}",
        	patters = { "." },
        	fallback = true
              },
              spec = {
                { "LazyVim/LazyVim", import = "lazyvim.plugins" },
        	{ "nvim-telescope/telescope-fzf-native.nvim", enabled = true },
        	-- disable mason plugin manager because plugins are managed by nix
        	{ "williamboman/mason-lspconfig.nvim", enabled = false },
        	{ "williamboman/mason.nvim", enabled = false },
        	-- import plugins
        	{ import = "plugins" },
        	-- treesitter config
        	{ "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = {} } },
              },
              })
      '';
    };
    #  let
    #    nixvim' = nivxim.legacyPackages."${system}";
    #    nvim = nixvim'.makeNixvim config;
    #  in
    #  {
    #    packages = {
    #      inherit nvim;
    #      default = nvim;
    #    };
    #  };
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

