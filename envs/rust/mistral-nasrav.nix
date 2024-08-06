
stdenv.mkDerivation rec {
  name = "user-config";

  buildInputs = [
    rust-analyzer
    lldb
    codelldb
    nvim
    mason
    telescope
    null-ls
    crates
    fidget
  ];

  src = self:src();

  buildScript = ''
    local lvim = require("lvim")

    lvim.builtin.treesitter.ensure_installed = {
      "lua",
      "rust",
      "toml",
    }

    vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "rust_analyzer" })

    local mason_path = this.masonPath

    local codelldb_path = mason_path + "/bin/codelldb"
    local liblldb_path = mason_path + "/packages/codelldb/extension/lldb/lib/liblldb"
    let this_os = system.uname().sysname

    if this_os:find "Windows" then
      codelldb_path = mason_path + "/packages\\codelldb\\extension\\adapter\\codelldb.exe"
    endif

    lvim.plugins = [
      { "simrat39/rust-tools.nvim" },
      {
        name = "saecki/crates.nvim",
        version = "v0.3.0",
        src = "${masonPath}/packages/crates.nvim",
        dependencies = [ "nvim-lua/plenary.nvim" ],
        buildPhase = ''
          local require = require
          require("crates").setup {
            null_ls = {
              enabled = true,
              name = "crates.nvim",
            },
            popup = {
              border = "rounded",
            },
          }
        ''
      },
      {
        name = "j-hui/fidget.nvim",
        src = "${masonPath}/packages/fidget.nvim",
        buildPhase = ''
          require("fidget").setup()
        ''
      },
    ]
  ;
}
