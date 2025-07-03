local M = {}

local core = require("streamline.core.core")

function M.setup(opts)
	opts = opts or {}
	core.config = vim.tbl_extend("force", {
		default_insert_behavior = "end",
	}, opts)

	core:init()
end

return M
