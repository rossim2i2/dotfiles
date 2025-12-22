return {
	"David-Kunz/gen.nvim",
	opts = {
		model = "zettel",
		host = "127.0.0.1",
		port = "11434",
		display_mode = "split",
		result_filetype = "markdown",
	},
	config = function(_, opts)
		local gen = require("gen")
		gen.setup(opts)

		gen.prompts["ZK_Atomic"] = {
			model = "zettel",
			replace = false,
			prompt = [[
Convert the following into Zettelkasten-style atomic notes.

Return in this exact format:

## Title
...
## Tags
- ...
## Atomic notes
1. ...
2. ...
## Backlinks
- ...
- ...

Text:
$text
]],
		}

		gen.prompts["ZK_TitleTags"] = {
			model = "zettel",
			replace = false,
			prompt = [[
Give me: (1) a concise note title, (2) 3–7 tags.
Text:
$text
]],
		}

		gen.prompts["ZK_Rewrite"] = {
			model = "zettel",
			replace = false,
			prompt = [[
Rewrite the following clearly and concisely for a note. Preserve meaning. Use bullet points where helpful.
Text:
$text
]],
		}
	end,
}
