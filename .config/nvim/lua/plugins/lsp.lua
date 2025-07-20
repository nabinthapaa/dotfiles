return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			'saghen/blink.cmp',
			{
				"folke/lazydev.nvim",
				ft = "lua", -- only load on lua files
				opts = {
					library = {
						{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
					},
				},
			},
		},
		opts = {
			inlay_hints = { enabled = true }
		},
		config = function()
			local lspconfig = require("lspconfig")
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			vim.diagnostic.config({
				virtual_text = false,
				signs = true,
				underline = true,
				update_in_insert = true
			})

			local on_attach = function(client, bufnr)
				local mapkey = vim.keymap.set
				mapkey("n", "<leader>cf", function() vim.lsp.buf.format() end, { buffer = bufnr, desc = "Format code" })
				mapkey("n", "gd", vim.lsp.buf.definition, { desc = "Go to Definition" })
				mapkey("n", "gr", vim.lsp.buf.references, { desc = "Go to References" })


				if not client.supports_method('textDocument/willSaveWaitUntil')
						and client.supports_method('textDocument/formatting') then
					vim.api.nvim_create_autocmd('BufWritePre', {
						buffer = bufnr,
						callback = function()
							vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 1000 })
						end,
					})
				end
			end

			local servers = require("config.lsp.servers").servers

			for _, server in ipairs(servers) do
				lspconfig[server].setup({
					capabilities = capabilities,
					on_attach = on_attach,
					lazy = true
				})
			end
		end
	}
}
