return {
	'nvim-telescope/telescope.nvim',
	tag = '0.1.8',
	dependencies = {
		'nvim-lua/plenary.nvim',
		{
			'nvim-telescope/telescope-fzf-native.nvim',
			build = 'make'
		}
	},
	config = function()
		local mapkey = vim.keymap.set

		mapkey("n", "<leader>gd", require("telescope.builtin").lsp_definitions, { desc = "Go to Definition" })
		mapkey("n", "<leader>gr", require("telescope.builtin").lsp_references, { desc = "Go to References" })
		mapkey("n", "<leader>gy", require("telescope.builtin").lsp_type_definitions, { desc = "Go to References" })
		mapkey('n', '<leader>gi', require("telescope.builtin").lsp_implementations, { desc = "Go to imlementation" })
		mapkey("n", "<leader>ds", require("telescope.builtin").lsp_document_symbols, { desc = "Document Symbols" })

		mapkey("n", "<leader>ff", require("telescope.builtin").find_files, { desc = "Find files" })

		mapkey(
			"n",
			"<leader>fb",
			function()
				require("telescope.builtin").buffers({ sort_mru = true, ignore_current_buffer = true })
			end,
			{ desc = "Search open buffers" }
		)

		mapkey("n", "<leader>fh", require("telescope.builtin").help_tags, { desc = "Help tags" })

		vim.keymap.set("n", "<leader>fc", function()
				require("telescope.builtin").find_files({
					cwd = vim.fn.stdpath("config")
				})
			end,
			{ desc = "Open nvim config files" }
		)
		vim.keymap.set("n", "<leader>fp", function()
				require("telescope.builtin").find_files({
					cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")
				})
			end,
			{ desc = "Open installed plugins files" }
		)
		require("config.telescope.multigrep").setup()
	end

}
