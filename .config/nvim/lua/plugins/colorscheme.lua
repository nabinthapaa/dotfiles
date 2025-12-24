-- return {
--   {
--   "LazyVim/LazyVim",
--   opts = {
--     colorscheme = false,
--   },
--   config = function()
--     vim.opt.termguicolors = true
--
--     local wal = vim.fn.expand("~/.cache/wal/colors-wal.vim")
--     if vim.fn.filereadable(wal) == 1 then
--       vim.cmd("source " .. wal)
--     end
--   end,
-- }
-- }

return {
  "folke/tokyonight.nvim",
  lazy = true,
  opts = {
    style = "storm",
    transparent = true,
    styles = {
      sidebars = "transparent",
      floats = "transparent",
    },
  },
}
