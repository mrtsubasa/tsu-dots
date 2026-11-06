-- Editor tabs, IDE style: flat, no slants, active tab underlined in accent blue.
local function jetbrains_highlights()
	if vim.g.colors_name ~= "jetbrains" then
		return {}
	end
	local c = require("jetbrains.palette")
	local bg = vim.g.jetbrains_transparent and "NONE" or c.bg
	local inactive = { fg = c.fg_dim, bg = bg }
	local selected = { fg = c.fg_bright, bg = bg, sp = c.accent, underline = true, italic = false, bold = false }
	return {
		fill = { bg = bg },
		background = inactive,
		buffer_visible = inactive,
		buffer_selected = vim.tbl_extend("force", selected, { bold = false, italic = false }),
		close_button = inactive,
		close_button_visible = inactive,
		close_button_selected = selected,
		modified = { fg = c.vcs_modified, bg = bg },
		modified_visible = { fg = c.vcs_modified, bg = bg },
		modified_selected = vim.tbl_extend("force", selected, { fg = c.vcs_modified }),
		duplicate = vim.tbl_extend("force", inactive, { italic = false, fg = c.fg_muted }),
		duplicate_visible = vim.tbl_extend("force", inactive, { italic = false, fg = c.fg_muted }),
		duplicate_selected = vim.tbl_extend("force", selected, { italic = false, fg = c.fg_dim }),
		indicator_visible = inactive,
		indicator_selected = { fg = c.accent, bg = bg, sp = c.accent, underline = true },
		separator = { fg = bg, bg = bg },
		separator_visible = { fg = bg, bg = bg },
		separator_selected = { fg = bg, bg = bg },
		offset_separator = { fg = c.bg, bg = bg },
		tab = inactive,
		tab_selected = selected,
		tab_close = inactive,
		numbers = inactive,
		numbers_selected = selected,
		diagnostic = inactive,
		diagnostic_selected = selected,
		error = { fg = c.error, bg = bg, sp = c.error },
		error_selected = vim.tbl_extend("force", selected, { fg = c.error }),
		error_diagnostic = { fg = c.error, bg = bg },
		error_diagnostic_selected = vim.tbl_extend("force", selected, { fg = c.error }),
		warning = { fg = c.warning, bg = bg },
		warning_selected = vim.tbl_extend("force", selected, { fg = c.warning }),
		warning_diagnostic = { fg = c.warning, bg = bg },
		warning_diagnostic_selected = vim.tbl_extend("force", selected, { fg = c.warning }),
		pick = { fg = c.keyword, bg = bg, bold = true },
		pick_selected = vim.tbl_extend("force", selected, { fg = c.keyword, bold = true }),
		pick_visible = { fg = c.keyword, bg = bg, bold = true },
	}
end

return {
	"akinsho/bufferline.nvim",
	event = "VeryLazy",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	keys = {
		{ "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous Buffer" },
		{ "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
		{ "<A-Left>", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous Tab" },
		{ "<A-Right>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Tab" },
		{ "<leader>bp", "<cmd>BufferLineTogglePin<cr>", desc = "Pin / Unpin Buffer" },
		{ "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "Close Other Buffers" },
		{ "<leader>b[", "<cmd>BufferLineMovePrev<cr>", desc = "Move Buffer Left" },
		{ "<leader>b]", "<cmd>BufferLineMoveNext<cr>", desc = "Move Buffer Right" },
	},
	opts = function()
		return {
			highlights = jetbrains_highlights(),
			options = {
				diagnostics = "nvim_lsp",
				always_show_bufferline = true,
				show_buffer_close_icons = true,
				show_close_icon = false,
				separator_style = { "", "" },
				indicator = { style = "none" },
				tab_size = 12,
				max_name_length = 24,
				modified_icon = "●",
				buffer_close_icon = "󰅖",
				hover = { enabled = true, delay = 120, reveal = { "close" } },
				offsets = {
					{
						filetype = "neo-tree",
						text = "  Project",
						highlight = "JBPanelTitle",
						text_align = "left",
						separator = false,
					},
				},
				-- Only colored names, like the IDE (errors in red, warnings in yellow)
				diagnostics_indicator = function()
					return ""
				end,
			},
		}
	end,
	config = function(_, opts)
		require("bufferline").setup(opts)
		-- Re-apply the IDE colors when the scheme is reloaded
		vim.api.nvim_create_autocmd("ColorScheme", {
			group = vim.api.nvim_create_augroup("jetbrains_bufferline", { clear = true }),
			callback = function()
				opts.highlights = jetbrains_highlights()
				require("bufferline").setup(opts)
			end,
		})
	end,
}
