return {
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			bigfile = { enabled = true },
			dashboard = {
				enabled = true,
				sections = require("config.snacks.dashboard").setup,
			},
			explorer = { enabled = false },
			indent = { enabled = true },
			input = { enabled = false },
			picker = { enabled = false },
			notifier = { enabled = true },
			quickfile = { enabled = true },
			scope = { enabled = true },
			scroll = { enabled = true },
			statuscolumn = { enabled = false },
			words = { enabled = false },
			zen = { enabled = true }
		},
	}
}
