return {
	{
		"stevearc/conform.nvim",
		optional = true,
		opts = {
			formatters_by_ft = {
				php = { "pint", "php_cs_fixer" },
			},
		},
	},
	{
		"mfussenegger/nvim-lint",
		optional = true,
		opts = {
			linters_by_ft = {
				php = {},
			},
		},
	},
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			vim.list_extend(opts.ensure_installed, {
				"blade",
				"php_only",
			})
		end,
		config = function(_, opts)
			vim.filetype.add({
				pattern = {
					[".*%.blade%.php"] = "blade",
				},
			})

			require("nvim-treesitter.configs").setup(opts)

			local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
			parser_config = {
				blade = {
					install_info = {
						url = "https://github.com/EmranMR/tree-sitter-blade",
						files = { "src/parser.c" },
						branch = "main",
					},
					filetype = "blade",
				}
			}
		end,
	},
	{
		"adalessa/laravel.nvim",
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"tpope/vim-dotenv",
			"MunifTanjim/nui.nvim",
			"kevinhwang91/promise-async"
		},
		cmd = { "Sail", "Artisan", "Composer", "Npm", "Yarn", "Laravel" },
		keys = {
			{ "<leader>pa", ":Laravel artisan<cr>", desc = "Laravel Artisan" },
			{ "<leader>pr", ":Laravel routes<cr>",  desc = "Laravel Routes" },
			{ "<leader>pm", ":Laravel related<cr>", desc = "Laravel Related" },
		},
		config = true,
		opts = {
			lsp_server = "intelephense",
		},
	}
}
