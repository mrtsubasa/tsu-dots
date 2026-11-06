return {
	-- Surround text objects: cs"' change, ds" delete, ys<motion>) add
	{
		"kylechui/nvim-surround",
		version = "*",
		event = "VeryLazy",
		opts = {},
	},

	-- Highlight and search TODO / FIXME / NOTE / HACK / WARN comments
	{
		"folke/todo-comments.nvim",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = true },
		keys = {
			{ "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find Todos" },
			{
				"]t",
				function()
					require("todo-comments").jump_next()
				end,
				desc = "Next Todo Comment",
			},
			{
				"[t",
				function()
					require("todo-comments").jump_prev()
				end,
				desc = "Previous Todo Comment",
			},
		},
	},
}
