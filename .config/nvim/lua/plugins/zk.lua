return {
  "zk-org/zk-nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },

  config = function()
    require("zk").setup({
      picker = "telescope",
      lsp = {
        config = {
          name = "zk",
          cmd = { "zk", "lsp" },
          filetypes = { "markdown" },
        },
        auto_attach = {
          enabled = true,
        },
      },
    })

    local zk_cmd = require("zk.commands")
    local zet_path = vim.fn.expand("~/zet")

    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, {
        noremap = true,
        silent = true,
        desc = desc,
      })
    end

    -- New note (always in ~/zet)
    map("<leader>zn", function()
      zk_cmd.get("ZkNew")({ notebook_path = zet_path })
    end, "Zk: New note")

    -- Open notes (Telescope, always uses ~/zet)
    map("<leader>zo", function()
      zk_cmd.get("ZkNotes")({
        sort = { "modified" },
        notebook_path = zet_path,
      })
    end, "Zk: Open note")

    -- Grep notes
    map("<leader>zg", function()
      zk_cmd.get("ZkGrep")({
        notebook_path = zet_path,
      })
    end, "Zk: Grep notes")

    -- Browse tags
    map("<leader>zt", function()
      zk_cmd.get("ZkTags")({
        notebook_path = zet_path,
      })
    end, "Zk: Tags")
  end,
}
