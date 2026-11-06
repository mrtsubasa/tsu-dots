local opt = vim.opt

opt.number = true -- Show line number
opt.relativenumber = false -- Absolute numbers, like the IDE gutter
opt.tabstop = 4 -- Tab size
opt.shiftwidth = 4 -- Indentation size
opt.expandtab = true -- Convert Tab to Spaces
opt.autoindent = true -- Keep indentation on new line
opt.wrap = false -- No soft wrap, like the IDE (toggle with <leader>uw)
opt.ignorecase = true -- Search ignores case...
opt.smartcase = true -- ...unless you type an uppercase letter
opt.cursorline = true -- Highlight current line
opt.termguicolors = true -- True colors (24-bit)
opt.scrolloff = 8 -- Keep 8 lines of margin when scrolling
opt.sidescrolloff = 8
-- opt.clipboard = "unnamedplus" -- Integrate with system clipboard

-- ============================================================================
-- IDE LOOK
-- ============================================================================
opt.signcolumn = "yes" -- Stable gutter (git bars, breakpoints-like signs)
opt.colorcolumn = "120" -- Right margin guide
opt.laststatus = 3 -- One status bar for the whole window
opt.showmode = false -- Mode is in the status bar
opt.cmdheight = 1
opt.pumheight = 12 -- Completion popup height
opt.splitright = true
opt.splitbelow = true
opt.mouse = "a"
opt.mousemoveevent = true -- Hover on tabs (close button)
opt.smoothscroll = true
opt.list = true
opt.listchars = { tab = "  ", trail = "·", nbsp = "␣" }
opt.fillchars = {
	eob = " ",
	fold = " ",
	foldopen = "\u{eab4}",
	foldclose = "\u{eab6}",
	foldsep = " ",
	vert = "│",
	horiz = "─",
}

-- Transparent background (lets the terminal/wallpaper show through)
vim.g.jetbrains_transparent = false

-- Leader Key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ============================================================================
-- FOLD CONFIGURATION
-- ============================================================================
opt.foldmethod = "expr" -- Use Treesitter intelligence to determine where to fold
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"

opt.foldlevel = 99 -- Start with everything open (only folds at level 99+)
opt.foldlevelstart = 99 -- Ensure new files open expanded
opt.foldenable = true -- Enable the system (but starts open because of 99)
