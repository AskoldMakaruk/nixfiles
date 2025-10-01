-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("i", "jk", "<esc>")
vim.keymap.set("i", "ол", "<esc>")

vim.keymap.set("n", "H", "^")
vim.keymap.set("n", "L", "$")
vim.keymap.set("i", "<c-space>", vim.fn["coc#refresh"]())

-- Define CheckBackspace function
_G.CheckBackspace = function()
  local col = vim.fn.col(".") - 1
  return col == 0 or vim.fn.getline("."):sub(col, col):match("%s") ~= nil
end

-- Set up the Tab mapping
vim.keymap.set("i", "<Tab>", function()
  if vim.fn["coc#pum#visible"]() == 1 then
    return vim.fn["coc#pum#next"](1)
  elseif _G.CheckBackspace() then
    return "<Tab>"
  else
    vim.fn["coc#refresh"]()
    return ""
  end
end, { expr = true, silent = true })
