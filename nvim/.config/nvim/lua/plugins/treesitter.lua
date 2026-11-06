return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	config = function()
		local parsers = {
			-- Core / editor
			"c",
			"cpp",
			"lua",
			"luadoc",
			"vim",
			"vimdoc",
			"query",
			"comment",
			"regex",
			"diff",
			-- Web
			"javascript",
			"typescript",
			"tsx",
			"html",
			"css",
			"scss",
			"json",
			"jsdoc",
			-- Systems / backend
			"go",
			"gomod",
			"gosum",
			"gowork",
			"rust",
			"python",
			"java",
			"sql",
			-- Shell / config / ops
			"bash",
			"toml",
			"yaml",
			"ini",
			"dockerfile",
			"make",
			"cmake",
			"xml",
			-- Git
			"gitcommit",
			"gitignore",
			"git_config",
			"gitattributes",
			-- Docs
			"markdown",
			"markdown_inline",
		}

		-- Install above parsers if they are missing.
		-- The main branch compiles parsers with the tree-sitter CLI: without it,
		-- every parser fails loudly, so warn once instead.
		vim.defer_fn(function()
			if vim.fn.executable("tree-sitter") == 1 then
				require("nvim-treesitter").install(parsers)
			else
				vim.notify(
					"tree-sitter CLI missing: sudo pacman -S tree-sitter-cli",
					vim.log.levels.WARN,
					{ title = "nvim-treesitter" }
				)
			end
		end, 1000)

		-- auto-start highlights & indentation
		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("Custom_enable_treesitter_features", {}),
			callback = function(args)
				local buf = args.buf
				local filetype = args.match

				-- checks if a parser exists for the current language
				local language = vim.treesitter.language.get_lang(filetype) or filetype
				if not vim.treesitter.language.add(language) then
					return
				end

				-- highlights
				vim.treesitter.start(buf, language)

				-- indent
				vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				-- folding
				vim.wo.foldmethod = "expr"
				vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
			end,
		})
	end,
}
