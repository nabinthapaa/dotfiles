return {
	{
		'echasnovski/mini.nvim',
		config = function()
			local statusline = require 'mini.statusline'
			local surround = require 'mini.surround'
			local pairs = require 'mini.pairs'
			-- local diagnostics = require "mini.diagonostics"

			statusline.setup { use_icons = true }
			surround.setup()
			pairs.setup()
			-- diagnostics.setup()
		end,
		version = "*"
	},
}
