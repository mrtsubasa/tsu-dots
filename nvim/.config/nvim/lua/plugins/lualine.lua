-- JetBrains-style status bar:
--   left  : project › path › file › symbol   (navigation bar / breadcrumbs)
--   right : diagnostics · LSP · line:col · LF · UTF-8 · 2 spaces · branch
local sep = "%#JBCrumbSep# \u{eab6} "

local function breadcrumbs()
	local file = vim.api.nvim_buf_get_name(0)
	if file == "" or vim.bo.buftype ~= "" then
		return ""
	end

	local root = vim.fn.getcwd()
	local parts = { "%#JBCrumb#" .. vim.fn.fnamemodify(root, ":t") }
	local rel = vim.fn.fnamemodify(file, ":.")
	-- File outside the project: show it from ~ instead
	if rel:sub(1, 1) == "/" then
		parts = { "%#JBCrumb#" .. "~" }
		rel = vim.fn.fnamemodify(file, ":~"):gsub("^~/", "")
	end

	local segments = vim.split(rel, "/", { plain = true })
	for i, seg in ipairs(segments) do
		if i == #segments then
			local icon, icon_hl = "", "JBCrumbFile"
			local ok, devicons = pcall(require, "nvim-web-devicons")
			if ok then
				local ic, ic_hl = devicons.get_icon(seg, vim.fn.fnamemodify(seg, ":e"), { default = true })
				icon, icon_hl = ic or "", ic_hl or icon_hl
			end
			parts[#parts + 1] = "%#" .. icon_hl .. "#" .. icon .. " %#JBCrumbFile#" .. seg
		else
			parts[#parts + 1] = "%#JBCrumb#" .. seg
		end
	end

	local ok_navic, navic = pcall(require, "nvim-navic")
	if ok_navic and navic.is_available() then
		local loc = navic.get_location()
		if loc ~= "" then
			parts[#parts + 1] = loc
		end
	end

	return table.concat(parts, sep)
end

local function indent()
	if vim.bo.buftype ~= "" then
		return ""
	end
	if vim.bo.expandtab then
		return vim.bo.shiftwidth .. " spaces"
	end
	return "Tab " .. vim.bo.tabstop
end

local function lsp_names()
	local names = {}
	for _, client in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
		names[#names + 1] = client.name
	end
	return #names > 0 and ("\u{eb51} " .. table.concat(names, ", ")) or ""
end

return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("lualine").setup({
			options = {
				-- The IDE theme when it's active, otherwise derive from the colorscheme
				theme = vim.g.colors_name == "jetbrains" and "jetbrains" or "auto",
				component_separators = "",
				section_separators = "",
				globalstatus = true,
				disabled_filetypes = { statusline = { "snacks_dashboard" } },
			},
			sections = {
				lualine_a = {
					{ "mode", fmt = function(m) return m:sub(1, 1) end, padding = 1 },
				},
				lualine_b = {},
				lualine_c = {
					{ breadcrumbs, padding = { left = 1, right = 0 } },
				},
				lualine_x = {
					{
						"diagnostics",
						sources = { "nvim_diagnostic" },
						symbols = { error = "\u{ea87} ", warn = "\u{ea6c} ", info = "\u{ea74} ", hint = "\u{ea61} " },
					},
					{ lsp_names },
					{ function() return vim.fn.line(".") .. ":" .. vim.fn.virtcol(".") end },
					{ "fileformat", symbols = { unix = "LF", dos = "CRLF", mac = "CR" } },
					{ "encoding", fmt = string.upper },
					{ indent },
				},
				lualine_y = {
					{ "branch", icon = "\u{e725}" },
				},
				lualine_z = {},
			},
			extensions = { "neo-tree", "lazy", "mason", "trouble" },
		})
	end,
}
