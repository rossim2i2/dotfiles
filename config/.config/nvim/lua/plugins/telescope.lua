return {
	"nvim-telescope/telescope.nvim",
	tag = "v0.2.0",
	dependencies = { "nvim-lua/plenary.nvim", { "nvim-telescope/telescope-fzf-native.nvim", build = "make" } },
	config = function()
		local telescope = require("telescope")
		telescope.setup({
			pickers = {
				find_files = {
					theme = "ivy",
				},
				extentions = {
					fzf = {},
				},
			},
		})

		require("telescope").load_extension("fzf")

		local builtin = require("telescope.builtin")
		local map = vim.keymap.set

		map("n", "<leader>ff", builtin.find_files, { desc = "[F]ind [F]iles" })
		map("n", "<leader>fg", builtin.live_grep, { desc = "[F]ind by [G]rep" })
		map("n", "<leader>fb", builtin.buffers, { desc = "[F]ind [B]uffers" })
		map("n", "<leader>fh", builtin.help_tags, { desc = "[F]ind [H]elp" })
		map("n", "<leader>en", function()
			builtin.find_files({
				cwd = vim.fn.stdpath("config"),
			})
		end)
		map("n", "<leader>fz", function()
			builtin.live_grep({
				cwd = "~/Repos/github.com/rossim2i2/zet",
			})
		end)
	end,
}
