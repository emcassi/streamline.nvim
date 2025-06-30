local M = {
	buffers = {},
	active = nil,
	ignore_buftypes = { "quickfix", "nofile" },
}

local function setup_commands()
	vim.api.nvim_create_user_command("StreamBuffers", function()
		require("streamline.ui"):print_buffers()
	end, { desc = "Print current buffer list" })
end

function M:init()
	local augroup = vim.api.nvim_create_augroup("streamline", { clear = true })
	vim.api.nvim_create_autocmd({ "BufAdd" }, {
		group = augroup,
		callback = function(g)
			self:on_buffer_added(g.buf)
		end,
	})
	vim.api.nvim_create_autocmd({ "BufDelete" }, {
		group = augroup,
		callback = function(g)
			self:on_buffer_removed(g.buf)
		end,
	})
	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		group = augroup,
		callback = function(g)
			self:on_buffer_entered(g.buf)
		end,
	})

	vim.api.nvim_create_autocmd({ "BufModifiedSet" }, {
		group = augroup,
		callback = function(args)
			local buf_id = args.buf
			if self:has_buffer(buf_id) then
				local is_modified = vim.api.nvim_buf_get_option(buf_id, "modified")
				self:on_buffer_modified(buf_id, is_modified)
			end
		end,
	})
	setup_commands()
	self:gather_buffers()
end

function M:get_buffers()
	return self.buffers
end

local function get_buffer_display_name(buf_id)
	local name = vim.api.nvim_buf_get_name(buf_id)

	if name ~= "" then
		return name
	end
	return "[No Name]"
end

function M:create_buffer_entry(buf_id)
	return {
		id = buf_id,
		name = vim.api.nvim_buf_get_name(buf_id),
		display_name = get_buffer_display_name(buf_id),
		modified = vim.api.nvim_buf_get_option(buf_id, "modified"),
	}
end

function M:on_buffer_modified(buf_id, is_modified)
	for _, buf in ipairs(self.buffers) do
		if buf.id == buf_id then
			buf.modified = is_modified
			break
		end
	end
end

local function is_empty_modified_buffer(buf_id)
	local name = vim.api.nvim_buf_get_name(buf_id)
	local modified = vim.api.nvim_buf_get_option(buf_id, "modified")
	local line_count = vim.api.nvim_buf_line_count(buf_id)
	return name == "" and line_count <= 1 and not modified
end

function M:gather_buffers()
	self.buffers = {}
	for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(buf_id) then
			local bt = vim.api.nvim_buf_get_option(buf_id, "buftype")
			if not vim.tbl_contains(self.ignore_buftypes, bt) then
				local name = vim.api.nvim_buf_get_name(buf_id)
				local display_name = get_buffer_display_name(buf_id)
				table.insert(self.buffers, self:create_buffer_entry(buf_id))
			end
		end
	end
end

function M:on_buffer_added(id)
	local bt = vim.api.nvim_buf_get_option(id, "buftype")
	if self.ignore_buftypes[bt] then
		return
	end
	for i, buf in ipairs(self.buffers) do
		if is_empty_modified_buffer(buf.id) then
			self.buffers[i] = self:create_buffer_entry(id)
			return
		end
	end

	if not self:has_buffer(id) then
		table.insert(self.buffers, self:create_buffer_entry(id))
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

function M:clean_empty_buffers()
	for i = #self.buffers, 1, -1 do
		local buf = self.buffers[i]
		if is_empty_modified_buffer(buf.id) then
			table.remove(self.buffers, i)
		end
	end
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

function M:teardown()
	vim.api.nvim_clear_autocmds({ group = "streamline" })
end
return M
