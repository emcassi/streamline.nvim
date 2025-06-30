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
	self.augroup = vim.api.nvim_create_augroup("streamline", { clear = true })
	vim.api.nvim_create_autocmd({ "BufAdd" }, {
		group = self.augroup,
		callback = function(g)
			self:on_buffer_added(g.buf)
		end,
	})
	vim.api.nvim_create_autocmd({ "BufDelete" }, {
		group = self.augroup,
		callback = function(g)
			self:on_buffer_removed(g.buf)
		end,
	})
	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		group = self.augroup,
		callback = function(g)
			self:on_buffer_entered(g.buf)
		end,
	})

	vim.api.nvim_create_autocmd({ "BufModifiedSet" }, {
		group = self.augroup,
		callback = function(args)
			local buf_id = args.buf
			if self:has_buffer(buf_id) then
				local is_modified = vim.bo[buf_id].modified
				self:on_buffer_modified_debounced(buf_id, is_modified)
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "BufFilePost" }, {
		group = self.augroup,
		callback = function(args)
			if self:has_buffer(args.buf) then
				local buf = self:get_buffer(args.buf)
				buf.display_name = self:get_buffer_display_name(args.buf)
			end
		end,
	})
	setup_commands()
	self:gather_buffers()
	self.active = vim.api.nvim_get_current_buf()
end

function M:get_buffer(buf_id)
	for _, buf in ipairs(self.buffers) do
		if buf.id == buf_id then
			return buf
		end
	end
	return nil
end

function M:get_buffers()
	return self.buffers
end

function M:get_buffer_display_name(buf_id)
	local success, name = pcall(vim.api.nvim_buf_get_name, buf_id)
	if not success then
		vim.notify("Failed to get buffer name", vim.log.levels.ERROR)
		return "[No Name]"
	end

	if name ~= "" then
		return name
	end
	return "[No Name]"
end

function M:create_buffer_entry(buf_id)
	local success, buf_name = pcall(vim.api.nvim_buf_get_name, buf_id)
	if not success then
		vim.notify("Failed to get buffer name", vim.log.levels.ERROR)
		return nil
	end

	return {
		id = buf_id,
		name = buf_name,
		display_name = self:get_buffer_display_name(buf_id),
		modified = vim.bo[buf_id].modified,
	}
end

local debounce_timer = nil
function M:on_buffer_modified_debounced(buf_id, is_modified)
	if debounce_timer then
		debounce_timer:close()
	end
	debounce_timer = vim.defer_fn(function()
		self:on_buffer_modified(buf_id, is_modified)
		debounce_timer = nil
	end, 200) -- 200ms delay
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
	local success, name = pcall(vim.api.nvim_buf_get_name, buf_id)
	if not success then
		vim.notify("Failed to get buffer name", vim.log.levels.ERROR)
		return false
	end
	local modified = vim.bo[buf_id].modified
	local line_count = vim.api.nvim_buf_line_count(buf_id)
	return name == "" and line_count <= 1 and not modified
end

function M:gather_buffers()
	self.buffers = {}
	for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(buf_id) then
			local bt = vim.bo[buf_id].buftype
			if not vim.tbl_contains(self.ignore_buftypes, bt) then
				local new_buf = self:create_buffer_entry(buf_id)
				if new_buf then
					table.insert(self.buffers, new_buf)
				end
			end
		end
	end
end

function M:on_buffer_added(id)
	local bt = vim.bo[id].buftype
	if vim.tbl_contains(self.ignore_buftypes, bt) then
		return
	end
	for i, buf in ipairs(self.buffers) do
		if is_empty_modified_buffer(buf.id) then
			local new_buf = self:create_buffer_entry(id)
			if new_buf then
				self.buffers[i] = new_buf
			end
			return
		end
	end

	if not self:has_buffer(id) then
		local new_buf = self:create_buffer_entry(id)
		if new_buf then
			table.insert(self.buffers, new_buf)
		end
	end
end

function M:has_buffer(id)
	return self:get_buffer(id) ~= nil
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
	if vim.api.nvim_buf_is_valid(id) and self:has_buffer(id) then
		self.active = id
	end
end

function M:get_active_buffer()
	for _, buf in ipairs(self.buffers) do
		if not self.active then
			return nil
		end

		if buf.id == self.active then
			return buf
		end
	end
	return nil
end

function M:get_active_index()
	if not self.active then
		return nil
	end

	for i, buf in ipairs(self.buffers) do
		if buf.id == self.active then
			return i
		end
	end
	return nil
end

function M:teardown()
	if self.augroup then
		vim.api.nvim_del_augroup_by_id(self.augroup)
		self.augroup = nil
	end
	if debounce_timer then
		debounce_timer:close()
		debounce_timer = nil
	end
end
return M
