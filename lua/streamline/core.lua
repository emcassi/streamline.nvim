local M = {
	buffers = {},
	active = nil,
}

function M:init()
	vim.api.nvim_create_autocmd({ "BufAdd" }, {
		callback = function(g)
			vim.notify(vim.inspect(g))
			M:sync_buffers()
		end,
	})
	M:sync_buffers()
end

function M:sync_buffers()
	local buffers = vim.api.nvim_list_bufs()
	local active = vim.api.nvim_get_current_buf()

	local new_buffers = {}
	for i, buf in ipairs(buffers) do
		if vim.api.nvim_buf_is_valid(buf) then
			table.insert(new_buffers, buf)
		else
			table.remove(self.buffers, i)
		end

		local name = vim.api.nvim_buf_get_name(buf)
		if name == "" then
			table.remove(self.buffers, i)
		end
	end

	self.buffers = new_buffers
	self.active = active

	local buffer_info = {}
	for _, buf in ipairs(self.buffers) do
		buffer_info[buf] = vim.api.nvim_buf_get_name(buf)
	end

	vim.notify(vim.inspect(buffer_info))
end

function M:get_active_buffer()
	return self.buffers[self:get_active_index()]
end

function M:get_active_index()
	for i, buf in ipairs(self.buffers) do
		if buf == self.active then
			return i
		end
	end
	return 1
end

return M
