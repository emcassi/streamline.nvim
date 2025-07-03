local M = {
	buffers = {},
	buffer_order = {},
	active_buf = nil,
	previous_buf = nil,
	ignore_buftypes = { "quickfix", "nofile" },
	navigating = false,
	augroup = vim.api.nvim_create_augroup("streamline", { clear = true }),
	config = {
		default_insert_behavior = "end",
	},
}

function M:init()
	require("streamline.core.events"):register_events()
	require("streamline.core.config"):setup_commands()
	require("streamline.core.buffer_state"):gather_buffers()
end

function M:get_active_buf()
	return self.active_buf
end

function M:get_previous_buf()
	return self.previous_buf
end

function M:insert_buffer_at_index(buf, index)
	table.insert(self.buffer_order, index, buf.id)
end

function M:insert_buffer_at_end(buf)
	table.insert(self.buffer_order, buf.id)
end

return M
