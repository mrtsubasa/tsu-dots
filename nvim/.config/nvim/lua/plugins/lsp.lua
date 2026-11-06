return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason-org/mason.nvim",
			"mason-org/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
		config = function()
			-- Language servers installed outside Mason (rustup / go install)
			local extra_paths = {
				vim.fn.expand("~/.cargo/bin"),
				vim.fn.expand("~/go/bin"),
				"/usr/lib/rustup/bin",
			}
			for _, dir in ipairs(extra_paths) do
				if vim.fn.isdirectory(dir) == 1 and not string.find(":" .. vim.env.PATH .. ":", ":" .. dir .. ":", 1, true) then
					vim.env.PATH = dir .. ":" .. vim.env.PATH
				end
			end

			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Per-server settings. Servers NOT listed here still get installed and
			-- enabled with the default `*` config, so adding a language is usually
			-- just adding its name to `ensure_installed` further down.
			local servers = {
				lua_ls = {
					settings = {
						Lua = {
							diagnostics = { globals = { "vim" } },
							workspace = { checkThirdParty = false },
							telemetry = { enable = false },
						},
					},
				},
				ts_ls = {
					settings = {
						-- WebStorm-style inline hints: variable types, parameter names on
						-- literals, return types. Toggle with <leader>uh.
						typescript = {
							inlayHints = {
								includeInlayParameterNameHints = "literals",
								includeInlayParameterNameHintsWhenArgumentMatchesName = false,
								includeInlayFunctionParameterTypeHints = true,
								includeInlayVariableTypeHints = true,
								includeInlayVariableTypeHintsWhenTypeMatchesName = false,
								includeInlayPropertyDeclarationTypeHints = true,
								includeInlayFunctionLikeReturnTypeHints = true,
								includeInlayEnumMemberValueHints = true,
							},
							preferences = {
								importModuleSpecifierPreference = "non-relative",
								includePackageJsonAutoImports = "auto",
							},
						},
						javascript = {
							inlayHints = {
								includeInlayParameterNameHints = "literals",
								includeInlayParameterNameHintsWhenArgumentMatchesName = false,
								includeInlayFunctionParameterTypeHints = true,
								includeInlayVariableTypeHints = true,
								includeInlayVariableTypeHintsWhenTypeMatchesName = false,
								includeInlayFunctionLikeReturnTypeHints = true,
							},
						},
					},
				},
			}

			-- Not managed by Mason: use the toolchain binaries already on the machine.
			local system_servers = {
				rust_analyzer = {
					cmd = { "rust-analyzer" },
					settings = {
						["rust-analyzer"] = {
							cargo = { allFeatures = true, loadOutDirsFromCheck = true },
							check = { command = "clippy" },
							procMacro = { enable = true },
							inlayHints = {
								closingBraceHints = { enable = true },
								parameterHints = { enable = true },
								typeHints = { enable = true },
							},
						},
					},
				},
				gopls = {
					cmd = { "gopls" },
					settings = {
						gopls = {
							gofumpt = false,
							staticcheck = true,
							usePlaceholders = true,
							completeUnimported = true,
							analyses = {
								unusedparams = true,
								shadow = true,
								nilness = true,
								unusedwrite = true,
							},
							hints = {
								assignVariableTypes = true,
								compositeLiteralFields = true,
								compositeLiteralTypes = true,
								constantValues = true,
								functionTypeParameters = true,
								parameterNames = true,
								rangeVariableTypes = true,
							},
						},
					},
				},
			}

			-- Neovim 0.11+ native API: register configs before mason-lspconfig enables servers
			vim.lsp.config("*", { capabilities = capabilities })
			for name, extra in pairs(vim.tbl_extend("force", servers, system_servers)) do
				vim.lsp.config(name, extra)
			end

			-- ========================================================================
			-- 1. VISUAL CONFIGURATION (Diagnostic) - Neovim 0.11+
			-- ========================================================================
			vim.diagnostic.config({
				virtual_text = false, -- off by default (toggle with <leader>ud)
				underline = true,
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = "",
						[vim.diagnostic.severity.WARN] = "",
						[vim.diagnostic.severity.HINT] = "",
						[vim.diagnostic.severity.INFO] = "",
					},
				},
				update_in_insert = false,
				severity_sort = true,
				float = { border = "rounded", source = true },
			})

			-- Long inferred types (Elysia<"", { decorator: {}; ... }>) are cut with "…"
			-- like WebStorm does, so a hint never runs off the screen.
			local max_hint = 30
			local on_inlayhint = vim.lsp.handlers["textDocument/inlayHint"]
			vim.lsp.handlers["textDocument/inlayHint"] = function(err, result, ctx, config)
				for _, hint in ipairs(result or {}) do
					local label = hint.label
					if type(label) == "table" then
						local parts = {}
						for _, part in ipairs(label) do
							parts[#parts + 1] = part.value
						end
						label = table.concat(parts)
					end
					if vim.fn.strchars(label) > max_hint then
						hint.label = vim.fn.strcharpart(label, 0, max_hint - 1) .. "…"
					end
				end
				return on_inlayhint(err, result, ctx, config)
			end

			-- ========================================================================
			-- 2. KEYBINDINGS ON ATTACH (LspAttach)
			-- ========================================================================
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
				callback = function(event)
					local tb = require("telescope.builtin")
					local map = function(keys, func, desc, mode)
						vim.keymap.set(mode or "n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					-- Breadcrumbs (barbecue winbar) for servers that expose symbols
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client.server_capabilities.documentSymbolProvider then
						local ok_navic, navic = pcall(require, "nvim-navic")
						if ok_navic then
							navic.attach(client, event.buf)
						end
					end

					-- Navigation
					map("gd", tb.lsp_definitions, "Go to Definition")
					map("gr", tb.lsp_references, "Go to References")
					map("gi", tb.lsp_implementations, "Go to Implementation")
					map("gy", tb.lsp_type_definitions, "Go to Type Definition")
					map("gD", vim.lsp.buf.declaration, "Go to Declaration")

					-- Info
					map("K", vim.lsp.buf.hover, "Hover Documentation")
					map("gl", function()
						vim.diagnostic.open_float({ scope = "line", border = "rounded", source = true, header = "", prefix = "" })
					end, "View Line Error (Float)")

					-- Actions
					map("<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
					map("<leader>ca", vim.lsp.buf.code_action, "Code Action", { "n", "v" })
					map("<leader>co", function()
						vim.lsp.buf.code_action({
							context = { only = { "source.organizeImports" }, diagnostics = {} },
							apply = true,
						})
					end, "Organize Imports")
					map("<leader>cS", tb.lsp_document_symbols, "Document Symbols")
					map("<leader>cw", tb.lsp_dynamic_workspace_symbols, "Workspace Symbols")

					-- Diagnostics navigation (0.11+ API)
					map("[d", function() vim.diagnostic.jump({ count = -1, float = false }) end, "Previous Diagnostic")
					map("]d", function() vim.diagnostic.jump({ count = 1, float = false }) end, "Next Diagnostic")

					-- Inline type / parameter hints ON, like WebStorm (toggle with <leader>uh)
					if client and client:supports_method("textDocument/inlayHint") then
						vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
					end
				end,
			})

			-- ========================================================================
			-- 3. AUTO-ORGANIZE IMPORTS ON SAVE (Go / TS / JS)
			--    Wrapped in pcall so a failure never blocks the save.
			-- ========================================================================
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = vim.api.nvim_create_augroup("lsp_organize_imports", { clear = true }),
				pattern = { "*.go", "*.ts", "*.tsx", "*.js", "*.jsx" },
				callback = function(args)
					pcall(function()
						local bufnr = args.buf
						local params = {
							textDocument = vim.lsp.util.make_text_document_params(bufnr),
							range = { start = { line = 0, character = 0 }, ["end"] = { line = 0, character = 0 } },
							context = { only = { "source.organizeImports" }, diagnostics = {} },
						}
						for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
							local res = client:request_sync("textDocument/codeAction", params, 1000, bufnr)
							if res and res.result then
								for _, action in ipairs(res.result) do
									if action.edit then
										vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
									elseif action.command then
										local cmd = type(action.command) == "table" and action.command or action
										client:request_sync("workspace/executeCommand", cmd, 1000, bufnr)
									end
								end
							end
						end
					end)
				end,
			})

			-- ========================================================================
			-- 4. MASON + TOOL INSTALLERS
			-- ========================================================================
			require("mason").setup()

			-- Formatters / linters (used by conform & co.)
			require("mason-tool-installer").setup({
				ensure_installed = {
					"stylua", -- lua
					"prettier", -- web
					"black", -- python
					"isort", -- python imports
					"shfmt", -- shell
					"clang-format", -- c / c++
				},
			})

			-- Language servers (broad coverage; add a line to support a new language)
			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls",
					"ts_ls",
					"html",
					"cssls",
					"tailwindcss",
					"emmet_ls",
					"eslint",
					"jsonls",
					"yamlls",
					"bashls",
					"pyright",
					"marksman", -- markdown
					"dockerls",
					"docker_compose_language_service",
					"taplo", -- toml
					"clangd", -- c / c++
				},
				-- v2: installed servers are enabled via vim.lsp.enable(); exclude the
				-- ones we start from system toolchains below.
				automatic_enable = { exclude = vim.tbl_keys(system_servers) },
			})

			vim.lsp.enable(vim.tbl_keys(system_servers))
		end,
	},
}
