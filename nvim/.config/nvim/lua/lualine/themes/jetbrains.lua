local c = require("jetbrains.palette")
local bar = vim.g.jetbrains_transparent and "NONE" or c.bg_panel

-- Flat IDE status bar: same grey everywhere, only the small mode tag is colored.
local function mode(color)
	return {
		a = { fg = c.bg, bg = color, gui = "bold" },
		b = { fg = c.fg_dim, bg = bar },
		c = { fg = c.fg_dim, bg = bar },
	}
end

return {
	normal = mode(c.accent),
	insert = mode(c.ok),
	visual = mode(c.property),
	replace = mode(c.error),
	command = mode(c.keyword),
	terminal = mode(c.number),
	inactive = {
		a = { fg = c.fg_muted, bg = bar },
		b = { fg = c.fg_muted, bg = bar },
		c = { fg = c.fg_muted, bg = bar },
	},
}
