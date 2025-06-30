local M = {
	buffers = {},
	active = nil,
}

local function setup_commands()
	vim.api.nvim_create_user_command("StreamBuffers", function()
		M:print_buffers()
	end, { desc = "Print current buffer list" })
end

function M:init()
	vim.api.nvim_create_autocmd({ "BufAdd" }, {
		callback = function(g)
			self:on_buffer_added(g.buf) -- Use self instead of M
		end,
	})
	vim.api.nvim_create_autocmd({ "BufDelete" }, {
		callback = function(g)
			self:on_buffer_removed(g.buf)
		end,
	})
	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		callback = function(g)
			self:on_buffer_entered(g.buf)
		end,
	})
	setup_commands()
	self:gather_buffers()
end

function M:get_buffers()
	return self.buffers
end

function M:gather_buffers()
	self.buffers = {}
	for _, id in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(id) then
			local name = vim.api.nvim_buf_get_name(id)
			if name ~= "" then
				table.insert(self.buffers, {
					id = id,
					name = name,
				})
			end
		end
	end
end

function M:on_buffer_added(id)
	if vim.api.nvim_buf_is_valid(id) then
		local name = vim.api.nvim_buf_get_name(id)
		if name ~= "" and not self:has_buffer(id) then
			table.insert(self.buffers, {
				id = id,
				name = name,
			})
		end
	end
end

function M:has_buffer(id)
	for _, buf in ipairs(self.buffers) do
		if buf.id == id then
			return true
		end
	end
	return false
end

function M:on_buffer_removed(id)
	for i, buf in ipairs(self.buffers) do
		if buf.id == id then
			table.remove(self.buffers, i)
			if self.active == id then
				self.active = nil
			end
			return
		end
	end
end

function M:on_buffer_entered(id)
	if vim.api.nvim_buf_is_valid(id) then
		self.active = id
	end
end

function M:get_active_buffer()
	for _, buf in ipairs(self.buffers) do
		if buf.id == self.active then
			return buf
		end
	end
	return nil
end

function M:get_active_index()
	for i, buf in ipairs(self.buffers) do
		if buf.id == self.active then
			return i
		end
	end
	return nil
end

function M:print_buffers()
	local message = ""
	local active_idx = self:get_active_index()
	if active_idx then
		message = string.format("Active buffer: %d/%d\n", active_idx, #self.buffers)
	end

	for i, buf in ipairs(self.buffers) do
		local active_marker = (buf.id == self.active) and " *" or ""
		message = message .. string.format("\n%2d: [%2d] %s%s\n", i, buf.id, buf.name, active_marker)
	end

	if message == "" then
		message = "No buffers open"
	end
	vim.notify(message, vim.log.levels.INFO)
end

return M
