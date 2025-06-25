return {
  "danymat/neogen",
  lazy = true,
  opts = {
    ['typescript.jsdoc'] = require('neogen.configurations.typescript')
  },

  require("neogen").setup({
    vim.api.nvim_set_keymap('n', '<leader>nfj', ':Neogen func<CR>', { noremap = true, silent = true })
  })
}
