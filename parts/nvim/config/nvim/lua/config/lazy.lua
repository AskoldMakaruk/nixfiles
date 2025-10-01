local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "plugins" },
    { "williamboman/mason-lspconfig.nvim", enabled = false },
    { "williamboman/mason.nvim", enabled = false },
    { "rafamadriz/friendly-snippets", enabled = false },
    { "Mofiqul/vscode.nvim" },
  },
  defaults = {
    lazy = false,
    version = false, -- always use the latest git commit
  },
  install = { colorscheme = { "tokyonight", "habamax", "gruvbox" } },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  news = { lazyvim = false, neovim = false },

  performance = {
    reset_packpath = false,
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

-- vim.lsp.enable("omnisharp")
vim.lsp.inlay_hint.enable(false)

vim.lsp.config("roslyn", {
  on_attach = function()
    -- print("This will run when the server attaches!")
  end,
  settings = {
    ["csharp|inlay_hints"] = {
      csharp_enable_inlay_hints_for_implicit_object_creation = true,
      csharp_enable_inlay_hints_for_lambda_parameter_types = false,
      csharp_enable_inlay_hints_for_implicit_variable_types = false,
      dotnet_enable_inlay_hints_for_other_parameters = false,
      dotnet_enable_inlay_hints_for_parameters = false,
    },
    ["csharp|code_lens"] = {
      dotnet_enable_references_code_lens = false,
    },
    ["csharp|background_analysis"] = {
      dotnet_analyzer_diagnostics_scope = "fullSolution",
      dotnet_compiler_diagnostics_scope = "fullSolution",
    },
    ["csharp|completion"] = {
      dotnet_show_completion_items_from_unimported_namespaces = true,
      dotnet_show_name_completion_suggestions = true,
    },
  },
})

vim.opt.shell = "zsh"

vim.o.background = "dark"

local c = require("vscode.colors").get_colors()
require("vscode").setup({
  -- Alternatively set style in setup
  -- style = 'light'

  -- Enable transparent background
  transparent = true,

  -- Enable italic comment
  italic_comments = true,

  -- Enable italic inlay type hints
  italic_inlayhints = true,

  -- Underline `@markup.link.*` variants
  underline_links = true,

  -- Disable nvim-tree background color
  disable_nvimtree_bg = true,

  -- Apply theme colors to terminal
  terminal_colors = true,

  -- Override colors (see ./lua/vscode/colors.lua)
  color_overrides = {
    vscLineNumber = "#FFFFFF",
  },

  -- Override highlight groups (see ./lua/vscode/theme.lua)
  group_overrides = {
    -- this supports the same val table as vim.api.nvim_set_hl
    -- use colors from this colorscheme by requiring vscode.colors!
    Cursor = { fg = c.vscDarkBlue, bg = c.vscLightGreen, bold = true },
  },
})
-- require('vscode').load()
--
vim.opt.langmap = table.concat({
  "йq,цw,уe,кr,еt,нy,гu,шi,щo,зp,х[,ї],фa,іs,вd,аf,пg,рh,оj,лk,дl,ж\\;,є',ґ\\,,",
  "яz,чx,сc,мv,иb,тn,ьm,ю.,./,ЙQ,ЦW,УE,КR,ЕT,НY,ГU,ШI,ЩO,ЗP,Х{,Ї},ФA,ІS,ВD,АF,",
  'ПG,РH,ОJ,ЛK,ДL,Ж\\:,Є",Ґ|,ЯZ,ЧX,СC,МV,ИB,ТN,ЬM,Б<,Ю>,№#',
}, "")
vim.opt.langremap = false
vim.cmd.colorscheme("vscode")

vim.opt.title = true
vim.opt.titlestring = [[%{luaeval('my_console_title()')}]]

function _G.my_console_title()
  local bufname = vim.api.nvim_buf_get_name(0)

  if bufname:match("zsh") then
    return "zsh: " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  end

  local filename = vim.fn.expand("%:t")
  local parent_dir = vim.fn.fnamemodify(bufname, ":h:t")

  if filename == "" then
    filename = "[No Name]"
    parent_dir = ""
  end

  local is_ro = vim.bo.readonly and "[RO]" or ""
  local is_help = vim.bo.buftype == "help" and "[HELP]" or ""

  local title_parts = {}

  -- local bufname = vim.api.nvim_buf_get_name(0)
  -- local dir = vim.fn.fnamemodify(bufname, ":h")
  -- while vim.fn.fnamemodify(dir, ":~") ~= "~/src" and dir ~= vim.fn.getcwd() and dir ~= "" do
  --   dir = vim.fn.fnamemodify(dir, ":h:h")
  --   table.insert(title_parts, 1, dir)
  -- end
  -- table.insert(title_parts, "/")
  -- table.insert(title_parts, filename)
  -- if true then
  --   return table.concat(title_parts)
  -- end

  if parent_dir ~= "." and parent_dir ~= "" then
    table.insert(title_parts, parent_dir)
  end
  table.insert(title_parts, "/")
  table.insert(title_parts, filename)
  if is_ro ~= "" or is_help ~= "" then
    table.insert(title_parts, is_ro .. " " .. is_help)
  end

  return table.concat(title_parts)
end
