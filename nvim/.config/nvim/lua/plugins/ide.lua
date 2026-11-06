return {
	-- Code symbols for the breadcrumbs in the status bar (lualine.lua).
	-- Attached to LSP clients in lsp.lua on_attach.
	{
		"SmiteshP/nvim-navic",
		lazy = true,
		opts = {
			highlight = true,
			separator = "%#NavicSeparator# \u{eab6} ",
			depth_limit = 4,
			lazy_update_context = true,
		},
	},

	-- IDE scrollbar on the right edge, with error / warning / git / search marks.
	{
		"lewis6991/satellite.nvim",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			current_only = true,
			winblend = 0,
			width = 2,
			excluded_filetypes = { "neo-tree", "snacks_dashboard", "snacks_terminal", "lazy", "mason" },
			handlers = {
				cursor = { enable = false },
				marks = { enable = false },
				gitsigns = { enable = true },
				diagnostic = { enable = true },
				search = { enable = true },
			},
		},
	},

	-- Signature help: a small popup showing the function's parameters and which
	-- one you are on, as you type inside the parentheses.
	{
		"ray-x/lsp_signature.nvim",
		event = "VeryLazy",
		opts = {
			hint_enable = false, -- no inline virtual text, just the floating window
			floating_window = true,
			floating_window_above_cur_line = true,
			handler_opts = { border = "rounded" },
		},
	},
}
