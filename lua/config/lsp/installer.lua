local M = {}

function M.setup(servers, server_options)
  local lspconfig = require("lspconfig")
  local icons = require("config.icons")

  require("mason").setup({
    ui = {
      icons = {
        package_installed = icons.server_installed,
        package_pending = icons.server_pending,
        package_uninstalled = icons.server_uninstalled,
      },
    },
  })

  require("mason-tool-installer").setup({
    ensure_installed = {
      "codelldb",
      "stylua",
      "shfmt",
      "shellcheck",
      "prettierd",
    },
    auto_update = false,
    run_on_start = true,
  })

  require("mason-lspconfig").setup({
    ensure_installed = vim.tbl_keys(servers),
    automatic_installation = false,
  })

  -- Package installation folder
  local install_root_dir = vim.fn.stdpath("data") .. "/mason"

  require("mason-lspconfig").setup_handlers({
    function(server_name)
      local opts = vim.tbl_deep_extend("force", server_options, servers[server_name] or {})
      lspconfig[server_name].setup(opts)
    end,
    ["rust_analyzer"] = function()
      local opts = vim.tbl_deep_extend("force", server_options, servers["rust_analyzer"] or {})

      -- DAP settings - https://github.com/simrat39/rust-tools.nvim#a-better-debugging-experience
      local extension_path = install_root_dir .. "/packages/codelldb/extension/"
      local codelldb_path = extension_path .. "adapter/codelldb"
      local liblldb_path = extension_path .. "lldb/lib/liblldb.so"
      require("rust-tools").setup({
        tools = {
          -- executor = require("rust-tools/executors").toggleterm,
          hover_actions = { border = "solid" },
          on_initialized = function()
            vim.api.nvim_create_autocmd({
              "BufWritePost",
              "BufEnter",
              "CursorHold",
              "InsertLeave",
            }, {
              pattern = { "*.rs" },
              callback = function()
                vim.lsp.codelens.refresh()
              end,
            })
          end,
          inlay_hints = { auto = false },
        },
        server = opts,
        dap = {
          adapter = require("rust-tools.dap").get_codelldb_adapter(codelldb_path, liblldb_path),
        },
      })
    end,
    ["tsserver"] = function()
      local opts = vim.tbl_deep_extend("force", server_options, servers["tsserver"] or {})
      require("typescript").setup({
        disable_commands = false,
        debug = false,
        server = opts,
      })
    end,
    -- ["elixirls"] = function()
    -- 	local opts = vim.tbl_deep_extend("force", server_options, servers["elixirls"] or {})
    -- 	local nls_utils = require("null-ls.utils")
    -- 	require("elixir").setup({
    -- 		cmd = "/home/andrew/.local/share/nvim/mason/packages/elixir-ls/language_server.sh",
    -- 		on_attach = function(client, bufnr)
    -- 			vim.api.nvim_buf_set_option(bufnr, "formatexpr", "v:lua.vim.lsp.formatexpr()")
    -- 			require("config.lsp.keymaps").setup(client, bufnr)
    -- 			-- Configure highlighting
    -- 			require("config.lsp.highlighter").setup(client, bufnr)
    -- 			-- Configure formatting
    -- 			require("config.lsp.null-ls.formatters").setup(client, bufnr)
    -- 			require("cmp_nvim_lsp").default_capabilities(opts.capabilities)
    -- 		end,
    -- 		root_dir = nls_utils.root_pattern(".git"),
    -- 	})
    -- end,
  })
end

return M
