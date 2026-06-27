return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          typescript = { "prettierd" }, -- Changed from "prettier"
          javascript = { "prettierd" }, -- Changed from "prettier"
          typescriptreact = { "prettierd" },
          javascriptreact = { "prettierd" },
          json = { "prettierd" },
          html = { "prettierd" },
          css = { "prettierd" },
          markdown = { "prettierd" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,
        },
      })
    end,
  },
}
