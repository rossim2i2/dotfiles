return {
  "nomnivore/ollama.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("ollama").setup({
      model = "zettel",
      url = "http://127.0.0.1:11434",
    })
  end,
}

