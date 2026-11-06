-- JetBrains "New UI Dark" palette (WebStorm / IntelliJ 2024+).
-- Shared by colors/jetbrains.lua, the lualine theme and bufferline.
return {
	-- Surfaces
	bg = "#1E1F22", -- editor
	bg_panel = "#2B2D30", -- tool windows (project tree, terminal, statusbar)
	bg_float = "#2B2D30",
	bg_line = "#26282E", -- caret row
	bg_hover = "#2E3036",
	bg_visual = "#214283",
	bg_select = "#2E436E", -- list selection (tree, completion)
	bg_hint = "#2F3135", -- inlay hint chip
	border = "#393B40",
	border_strong = "#43454A",

	-- Text
	fg = "#BCBEC4",
	fg_bright = "#DFE1E5",
	fg_dim = "#9DA0A8",
	fg_muted = "#6F737A",
	line_nr = "#4B5059",
	line_nr_cur = "#A1A3AB",
	hint = "#868A91",

	-- Accent
	accent = "#3574F0",

	-- Syntax
	keyword = "#CF8E6D",
	string = "#6AAB73",
	number = "#2AACB8",
	func = "#56A8F5",
	property = "#C77DBB",
	comment = "#7A7E85",
	doc = "#5F826B",
	annotation = "#B3AE60",
	type_param = "#16BAAC",
	constant = "#C77DBB",
	tag = "#D5B778",
	attr = "#BABABA",
	regex = "#42C3D4",
	label = "#32B8AF",

	-- Diagnostics
	error = "#F75464",
	warning = "#F2C55C",
	info = "#3592C4",
	ok = "#5FB865",

	-- VCS (gutter)
	git_add = "#549159",
	git_change = "#375FAD",
	git_delete = "#868A91",
	-- VCS (file names in the tree)
	vcs_added = "#73BD79",
	vcs_modified = "#70AEFF",
	vcs_untracked = "#D1675A",
	vcs_ignored = "#8C8C5A",
	vcs_conflict = "#DE6A66",
}
