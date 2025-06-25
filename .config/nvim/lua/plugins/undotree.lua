return {
  "mbbill/undotree",
  init = function()
    vim.keymap.set('n', '<leader>uu', vim.cmd.UndotreeToggle)
  end,
}
