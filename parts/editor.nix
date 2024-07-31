{ config, lib, pkgs, ... } : 

{
options = { batat.editor.enable = lib.mkEnableOption "enables editors"; };

config = lib.mkIf config.batat.editor.enable {

  programs.neovim = {
   enable = true;
    extraPackages = with pkgs; [
    lua-language-server
    stylua
    ripgrep
  };

  plugins = with pkgs.vimPlugins; [
    lazy-vim
  ];

  extraLuaConfig =
    let
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

	obsidian-nvim	
      ];
      mkEntryFromDrv = drv:
        if lib.isDerivation d then
	  { name = "${lib.getName d}"; path = d; }
	else
	  drv;
      lazyPath = pkgs.linkFarm "lazy-plugins" plugins;
    in
    ''
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
}
