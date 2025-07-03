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

function M:set_buffer(buf_id, buf)
	self.buffers[buf_id] = buf
end

function M:get_buffers() end

function M:get_buffer_order()
	return self.buffer_order
end

function M:get_buffer_by_id(buf_id)
	return self.buffers[buf_id]
end

function M:get_buffer_by_index(index)
	local buf_id = self.buffer_order[index]
	return buf_id and self.buffers[buf_id]
end

function M:get_active_buf()
	return self.active_buf
end

function M:get_active_buf_index()
	return self.active_buf and self.active_buf.index
end

function M:set_active_buffer(buf)
	self.active_buf = buf
end

function M:set_active_buffer_index(index)
	self.active_buf = self.buffers[self.buffer_order[index]]
end

function M:set_active_buffer_by_index(index)
	local buf_id = self.buffer_order[index]
	if buf_id then
		self.active_buf = self.buffers[buf_id]
	end
end

function M:get_previous_buf()
	return self.previous_buf
end

function M:set_previous_buf(buf)
	self.previous_buf = buf
end

function M:get_augroup()
	return self.augroup
end

function M:set_augroup(augroup)
	self.augroup = augroup
end

function M:should_ignore_buftype(bt)
	return vim.tbl_contains(self.ignore_buftypes, bt)
end

function M:get_is_navigating()
	return self.navigating
end

function M:set_is_navigating(is_navigating)
	self.navigating = is_navigating
end

function M:insert_buffer_at_index(buf, index)
	table.insert(self.buffer_order, index, buf.id)
end

function M:insert_buffer_at_end(buf)
	table.insert(self.buffer_order, buf.id)
end

function M:remove_buffer_by_id(buf_id)
	if self.buffers[buf_id] then
		local index = self.buffers[buf_id].index
		self:remove_buffer_at_index(index)
	end
end

function M:remove_buffer_at_index(index)
	local buf_id = self.buffer_order[index]

	if not vim.api.nvim_buf_is_valid(buf_id) then
		return
	end

	if vim.api.nvim_get_current_buf() == buf_id then
		vim.defer_fn(function()
			self.buffers[buf_id] = nil
		end, 10)
	else
		vim.api.nvim_buf_delete(buf_id, { force = true })
	end

	self.buffers[buf_id] = nil
	table.remove(self.buffer_order, index)
end

function M:clear_buffers()
	self.buffers = {}
	self.buffer_order = {}

	self.active_buf = nil
	self.previous_buf = nil

	for _, buf_id in ipairs(self.buffer_order) do
		vim.api.nvim_buf_delete(buf_id, { force = true })
	end
end

function M:teardown()
	if self.augroup then
		vim.api.nvim_del_augroup_by_id(self.augroup)
		self:set_augroup(nil)
	end

	require("streamline.core.buffer_state"):teardown()
end

return M
