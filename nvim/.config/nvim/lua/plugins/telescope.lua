return {
	"nvim-telescope/telescope.nvim",
	branch = "master",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		-- Makes vim.ui.select (code actions, etc.) use a nice Telescope window
		"nvim-telescope/telescope-ui-select.nvim",
	},
	keys = {
		-- Files & folders
		{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
		{ "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Find Text (grep)" },
		{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Open Buffers" },
		{ "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
		{ "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
		{ "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
		{ "<leader>fc", "<cmd>Telescope resume<cr>", desc = "Resume Last Search" },
		{ "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics (project)" },
		{ "<leader>fs", "<cmd>Telescope treesitter<cr>", desc = "Symbols (Treesitter)" },
		{
			"<leader>fw",
			function()
				require("telescope.builtin").grep_string({ search = vim.fn.expand("<cword>") })
			end,
			desc = "Find Word Under Cursor",
		},
		{
			"<leader>f/",
			function()
				require("telescope.builtin").current_buffer_fuzzy_find()
			end,
			desc = "Search In Current Buffer",
		},
	},
	config = function()
		local telescope = require("telescope")
		local themes = require("telescope.themes")

		telescope.setup({
			defaults = {
				path_display = { "truncate" }, -- keep enough path to tell files apart
				file_ignore_patterns = { "node_modules", "%.git/", "%.cache", "dist/", "build/", "target/" },
				sorting_strategy = "ascending",
				layout_strategy = "horizontal",
				layout_config = {
					horizontal = {
						prompt_position = "top",
						preview_width = 0.6,
					},
					width = 0.9,
					height = 0.88,
				},
			},
			pickers = {
				find_files = {
					hidden = true, -- show dotfiles (great for configs)
				},
			},
			extensions = {
				["ui-select"] = {
					themes.get_dropdown(),
				},
			},
		})

		-- Load extensions (fzf-native must be built; ui-select powers vim.ui.select)
		pcall(telescope.load_extension, "fzf")
		pcall(telescope.load_extension, "ui-select")
	end,
}
