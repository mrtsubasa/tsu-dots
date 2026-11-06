return {
	"folke/trouble.nvim",
	cmd = "Trouble",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		focus = true,
	},
	keys = {
		{ "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (project)" },
		{ "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnostics (buffer)" },
		{ "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols outline" },
		{ "<leader>xr", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "References / Definitions" },
		{ "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location List" },
		{ "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List" },
		-- IDE tool windows: Problems (Alt+6), Structure (Alt+7)
		{ "<A-6>", "<cmd>Trouble diagnostics toggle<cr>", desc = "Problems Tool Window" },
		{ "<A-7>", "<cmd>Trouble symbols toggle focus=false win.position=right<cr>", desc = "Structure Tool Window" },
	},
}
