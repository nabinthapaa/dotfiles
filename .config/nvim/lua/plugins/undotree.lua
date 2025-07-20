return {
	{
		"mbbill/undotree",
		lazy = false,
		init = function()
			vim.keymap.set('n', '<leader>uu', vim.cmd.UndotreeToggle, { desc = "Toggle Undo tree" })
		end,

	}
}
