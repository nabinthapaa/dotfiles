local mapkey = vim.keymap.set

mapkey("n", "<M-j>", "<cmd>cnext<CR>", { desc = "Next quickfix list reference" });
mapkey("n", "<M-k>", "<cmd>cprev<CR>", { desc = "Prev quickfix list reference" });
mapkey("n", "<leader>qq", "<cmd>wqa<CR>", { desc = "Quit neovim" });

mapkey("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Open diagnostics" })

mapkey("n", "]w", function()
	vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN })
end, { desc = "Go to next warning" })

mapkey("n", "]e", function()
	vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "Go to next error" })

mapkey("n", "[w", function()
	vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.WARN })
end, { desc = "Go to previous warning" })

mapkey("n", "[e", function()
	vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "Go to previous error" })

mapkey("n", '<leader>uh',
	function()
		vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
	end,
	{ desc = "Toggle inlay hints" }
)

mapkey("n", "<leader>st",
	function()
		vim.cmd.vnew()
		vim.cmd.term()
		vim.cmd.wincmd("J")
		vim.api.nvim_win_set_height(0, 15)
	end,
	{ desc = "Open terminal" }
);

mapkey("n", "<leader>ss", "<cmd>source $HOME/.config/nvim/init.lua<CR>", { desc = "Source init.lua" });
mapkey("n", "<leader>ss", "<cmd>source $HOME/.config/nvim/init.lua<CR>", { desc = "Source init.lua" });
mapkey("n", "<leader>-", vim.cmd.dsplit, { desc = "Split horizontally" })
mapkey("n", "<leader>|", vim.cmd.vsplit, { desc = "Split Vertically" })

mapkey("n", "<leader>lg", function()
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	})
	vim.fn.termopen("lazygit")
	vim.cmd("startinsert")
end, { desc = " LazyGit (float)" })
