return {
  {
    "mason-org/mason.nvim",
    lazy = false,
    config = function()
      require("mason").setup({
        registries = {
          "github:Crashdummyy/mason-registry",
          "github:mason-org/mason-registry",
        },
      })
    end,
  },
  {
    "seblyng/roslyn.nvim",
    ft = "cs",
    opts = {
      filewatching = "roslyn",
    },
  },
}
