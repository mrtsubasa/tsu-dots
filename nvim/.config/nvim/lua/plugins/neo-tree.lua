return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	cmd = "Neotree",
	keys = {
		{ "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Explorer (Toggle)" },
		{ "<A-1>", "<cmd>Neotree toggle<cr>", desc = "Project Tool Window" },
		{ "<leader>E", "<cmd>Neotree reveal<cr>", desc = "Select Opened File in Tree" },
	},
	-- Load neo-tree at startup if nvim is opened on a directory (e.g. `nvim .`),
	-- so it replaces netrw instead of showing the plain built-in explorer.
	init = function()
		if vim.fn.argc(-1) == 1 then
			local stat = vim.uv.fs_stat(vim.fn.argv(0))
			if stat and stat.type == "directory" then
				require("neo-tree")
			end
		end
	end,
	config = function()
		require("neo-tree").setup({
			popup_border_style = "rounded",
			enable_git_status = true,
			enable_diagnostics = true,
			-- The bufferline offset already draws the "Project" header
			source_selector = { winbar = false, statusline = false },

			-- IDE "Project" view: no guide lines, chevrons, outline folders,
			-- git state shown only by the file name color.
			default_component_configs = {
				container = { enable_character_fade = false },
				indent = {
					indent_size = 2,
					padding = 1,
					with_markers = false,
					with_expanders = true,
					expander_collapsed = "\u{eab6}",
					expander_expanded = "\u{eab4}",
					expander_highlight = "NeoTreeExpander",
				},
				icon = {
					folder_closed = "󰉋",
					folder_open = "󰝰",
					folder_empty = "󰉖",
					folder_empty_open = "󰷏",
					default = "󰈔",
				},
				modified = { symbol = "" },
				name = { trailing_slash = false, use_git_status_colors = true },
				git_status = {
					symbols = {
						added = "",
						modified = "",
						deleted = "",
						renamed = "",
						untracked = "",
						ignored = "",
						unstaged = "",
						staged = "",
						conflict = "",
					},
				},
				diagnostics = {
					symbols = { hint = "\u{ea61}", info = "\u{ea74}", warn = "\u{ea6c}", error = "\u{ea87}" },
				},
			},

			window = {
				position = "left",
				width = 36,
				mappings = {
					["l"] = "open",
					["h"] = "close_node",
					["<space>"] = "none",
					["Y"] = {
						function(state)
							local node = state.tree:get_node()
							local path = node:get_id()
							vim.fn.setreg("+", path, "c")
						end,
						desc = "Copy Absolute Path",
					},
				},
			},

			filesystem = {
				-- Take over directory buffers so `nvim .` opens neo-tree, not netrw
				hijack_netrw_behavior = "open_current",
				filtered_items = {
					visible = true,
					hide_dotfiles = false,
					hide_gitignored = false,
				},
				follow_current_file = { enabled = true },
				use_libuv_file_watcher = true, -- Auto-update if changed outside nvim
				group_empty_dirs = false,
			},
		})
	end,
}
