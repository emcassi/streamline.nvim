local M = {}

local core = require("streamline.core.core")
local buffer_state = require("streamline.core.buffer_state")

function M:register_events()
	vim.api.nvim_create_autocmd({ "BufAdd" }, {
		group = core.augroup,
		callback = function(g)
			buffer_state:on_buffer_added(g.buf)
		end,
	})

	vim.api.nvim_create_autocmd({ "BufDelete" }, {
		group = core.augroup,
		callback = function(g)
			buffer_state:on_buffer_removed(g.buf)
		end,
	})

	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		group = core.augroup,
		callback = function(g)
			buffer_state:on_buffer_entered(g.buf)
		end,
	})

	vim.api.nvim_create_autocmd({ "BufModifiedSet" }, {
		group = core.augroup,
		callback = function(args)
			local buf_id = args.buf
			if core.buffers[buf_id] then
				local is_modified = vim.bo[buf_id].modified
				buffer_state:on_buffer_modified_debounced(buf_id, is_modified)
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "BufFilePost" }, {
		group = core.augroup,
		callback = function(args)
			if core.buffers[args.buf] then
				core.buffers[args.buf].display_name = core:get_buffer_display_name(args.buf)
			end
		end,
	})
end

return M
