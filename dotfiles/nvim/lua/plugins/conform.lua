return {
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local conform = require("conform")

      conform.setup({
        formatters_by_ft = {
          lua = { "stylua" },
          yaml = { "yamlfix" },
          go = { "gofmt" },
        },
      })

      local map = require("helpers.keys").map
      local lfunc = function()
        conform.format({
          lsp_fallback = true,
          async = false,
          timeout_ms = 1000,
        })
      end

      map("n", "<leader>l", lfunc, "Format file or range (in visual mode)")
      map("v", "<leader>l", lfunc, "Format file or range (in visual mode)")
    end,
  }
}
