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
          {
            plugin = nvim-lspconfig;
            config = ''
              vim.diagnostic.config({
                virtual_text = false
              })

              -- Show line diagnostics automatically in hover window
              vim.o.updatetime = 250
              vim.cmd [[autocmd CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focus=false})]]
            '';
          }
          {
            plugin = conform-nvim;
            config = ''
            packadd! conform-nvim.lua
            lua << END
            require 'conform-nvim'.setup {
              opts = function()
                ---@type conform.setupOpts
                local opts = {
                  default_format_opts = {
                    timeout_ms = 3000,
                    async = false, -- not recommended to change
                    quiet = false, -- not recommended to change
                    lsp_format = "fallback", -- not recommended to change
                  },
                  formatters_by_ft = {
                    lua = { "stylua" },
                    fish = { "fish_indent" },
                    sh = { "shfmt" },
                    rust = { "rustfmt" },
                  },
                  formatters = {
                    injected = { options = { ignore_errors = true } },
                  },
                }
                return opts
              end
                }
                END
            '';
          }

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

          todo-comments-nvim
          vim-illuminate

          lazygit-nvim

          obsidian-nvim
          # knap # live file preview

          Ionide-vim # fsharp support
          rustaceanvim
          rust-vim
          rust-tools-nvim

          vim-ledger
        ];
      };

      home.packages = with pkgs; [

        fsautocomplete

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
