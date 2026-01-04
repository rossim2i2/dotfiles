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
		map("n", "<leader>fi", function()
			builtin.find_files({
				cwd = "~/Repos/github.com/rossim2i2/zet/inbox",
			})
		end)

		map("n", "<leader>fw", function()
			builtin.find_files({
				cwd = "~/Repos/github.com/rossim2i2/zet/_work/inbox",
			})
		end)

		-- Search all open tasks: lines like "- [ ] ..."
		map("n", "<leader>wa", function()
			require("telescope.builtin").live_grep({
				cwd = "~/Repos/github.com/rossim2i2/zet/_work",
				default_text = "^- \\[ \\] ",
				prompt_title = "Open actions (- [ ])",
			})
		end, { desc = "Tasks: search all open actions" })

		-- Prompt for a person (e.g. sarah) and search open tasks assigned to them
		map("n", "<leader>wp", function()
			vim.ui.input({ prompt = "Person (without @): " }, function(person)
				if not person or person == "" then
					return
				end
				require("telescope.builtin").live_grep({
					cwd = "~/Repos/github.com/rossim2i2/zet/_work",
					default_text = "^- \\[ \\] .*@" .. person .. "\\b",
					prompt_title = "Open actions for @" .. person,
				})
			end)
		end, { desc = "Tasks: search open actions by person" })
	end,
}
