return {
	{
		'stevearc/oil.nvim',
		opts = {},
		dependencies = { { "echasnovski/mini.icons", opts = {} } },
		lazy = false,
		config = function()
			vim.keymap.set("n", "<leader>e", require("oil").toggle_float, { desc = "Toggle Oil" })
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "oil",
				callback = function()
					vim.keymap.set("n", "h", "<cmd>Oil <CR>", { buffer = true, desc = "Go up directory" })
					vim.keymap.set("n", "l", require("oil").select, { buffer = true, desc = "Select" })
					vim.keymap.set("n", "q", require("oil").close, { buffer = true, desc = "Close Oil" })
					vim.keymap.set("n", "<Esc>", require("oil").close, { buffer = true, desc = "Close Oil" })
				end,
			})
		end
	}
}
