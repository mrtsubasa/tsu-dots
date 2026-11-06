return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		preset = "modern",
		spec = {
			{ "<leader>f", group = "Find / Files" },
			{ "<leader>g", group = "Git" },
			{ "<leader>b", group = "Buffer" },
			{ "<leader>c", group = "Code / LSP" },
			{ "<leader>x", group = "Diagnostics / Trouble" },
			{ "<leader>q", group = "Session" },
			{ "<leader>m", group = "Format" },
			{ "<leader>u", group = "UI / Toggle" },
			{ "<leader>s", group = "Search / Scratch" },
			{ "<leader>y", group = "Yank / Clipboard" },
			{ "<leader>d", group = "Delete / Paste" },
			{ "<leader>r", group = "Rename" },
			{ "g", group = "Goto" },
			{ "]", group = "Next" },
			{ "[", group = "Prev" },
		},
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Keymaps (which-key)",
		},
	},
}
