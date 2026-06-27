return {
  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- Mason for managing LSP servers (optional but recommended)
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      -- Setup Mason first
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "ts_ls" }, -- TypeScript/JavaScript LSP
      })

      local lspconfig = require("lspconfig")

      -- TypeScript LSP setup
      lspconfig.ts_ls.setup({
        -- Bun-specific settings
        init_options = {
          preferences = {
            -- Use Bun as the package manager
            packageManager = "bun",
          },
        },
        on_attach = function(client, bufnr)
          -- Keybindings for LSP features
          local opts = { buffer = bufnr, noremap = true, silent = true }

          -- Show errors/warnings inline
          vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)

          -- Navigate between diagnostics
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

          -- Show all diagnostics in location list
          vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts)
        end,
      })

      -- Show diagnostics inline as you type
      vim.diagnostic.config({
        virtual_text = true, -- Show errors inline
        signs = true,
        update_in_insert = false,
        underline = true,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
        },
      })
    end,
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", -- LSP completion source
      "hrsh7th/cmp-buffer", -- Buffer words completion
      "hrsh7th/cmp-path", -- File path completion
      "L3MON4D3/LuaSnip", -- Snippet engine
      "saadparwaiz1/cmp_luasnip", -- Snippet completion source
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" }, -- LSP completions (your TS types!)
          { name = "luasnip" }, -- Snippets
          { name = "buffer" }, -- Words from current buffer
          { name = "path" }, -- File paths
        }),
      })
    end,
  },
}
