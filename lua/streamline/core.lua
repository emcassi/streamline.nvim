local M = {
	buffers = {},
	active_buf = nil,
	previous_buf = nil,
	ignore_buftypes = { "quickfix", "nofile" },
	navigating = false,
}

local function setup_commands(m)
	vim.api.nvim_create_user_command("StreamBuffers", function()
		require("streamline.ui"):print_buffers()
	end, { desc = "Print current buffer list" })

	vim.api.nvim_create_user_command("StreamNavBackward", function()
		m:navigate_backward()
	end, { desc = "Navigate backward in buffer list" })

	vim.api.nvim_create_user_command("StreamNavForward", function()
		m:navigate_forward()
	end, { desc = "Navigate forward in buffer list" })

	vim.api.nvim_create_user_command("StreamNavToPrevious", function()
		m:navigate_to_previous()
	end, { desc = "Navigate to previous buffer" })

	vim.api.nvim_create_user_command("StreamNavToIndex", function(args)
		local index = tonumber(args.args)
		if index then
			m:navigate_to_index(index)
		else
			vim.notify("[streamline] Invalid index", vim.log.levels.ERROR)
		end
	end, { desc = "Navigate to buffer at index", nargs = 1 })
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
				self:get_buffer_by_id(args.buf).display_name = self:get_buffer_display_name(args.buf)
			end
		end,
	})

	setup_commands(self)
	self:gather_buffers()
end

function M:get_buffer_by_id(buf_id)
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

function M:get_buffer_index_from_id(buf_id)
	for i, b in ipairs(self.buffers) do
		if b.id == buf_id then
			return i
		end
	end
end

function M:get_buffer_display_name(buf_id)
	local success, name = pcall(vim.api.nvim_buf_get_name, buf_id)
	if not success then
		vim.notify("[streamline] Failed to get buffer name", vim.log.levels.ERROR)
		return "[No Name]"
	end

	if name ~= "" then
		return name
	end
	return "[No Name]"
end

function M:create_buffer_entry(buf_id, index)
	local success, buf_name = pcall(vim.api.nvim_buf_get_name, buf_id)
	if not success then
		vim.notify("[streamline] Failed to get buffer name", vim.log.levels.ERROR)
		return nil
	end

	return {
		id = buf_id,
		name = buf_name,
		index = index,
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
		vim.notify("[streamline] Failed to get buffer name", vim.log.levels.ERROR)
		return false
	end
	local modified
	success, modified = pcall(function()
		return vim.bo[buf_id].modified
	end)
	if not success then
		vim.notify("[streamline] Failed to get buffer modified", vim.log.levels.ERROR)
		return false
	end
	local line_count
	success, line_count = pcall(function()
		return vim.api.nvim_buf_line_count(buf_id)
	end)
	if not success then
		return false
	end
	return name == "" and line_count <= 1 and not modified
end

function M:gather_buffers()
	self.buffers = {}
	local success, buf_list = pcall(vim.api.nvim_list_bufs)
	if not success then
		vim.notify("[streamline] Failed to get buffer list", vim.log.levels.ERROR)
		self:teardown()
		return
	end

	for i, buf_id in ipairs(buf_list) do
		if vim.api.nvim_buf_is_valid(buf_id) then
			local bt = vim.bo[buf_id].buftype
			if not vim.tbl_contains(self.ignore_buftypes, bt) then
				local new_buf = self:create_buffer_entry(buf_id, i)
				if new_buf then
					if new_buf.id == vim.api.nvim_get_current_buf() then
						self:set_active_buffer_by_index(new_buf.index)
					end
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
			local new_buf = self:create_buffer_entry(id, i)
			if new_buf then
				self.buffers[i] = new_buf
			end
			return
		end
	end

	if not self:has_buffer(id) then
		local new_buf = self:create_buffer_entry(id, #self.buffers + 1)
		if new_buf then
			table.insert(self.buffers, new_buf)
		end
	end
end

function M:has_buffer(id)
	return self:get_buffer_by_id(id) ~= nil
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
			local success, _ = pcall(table.remove, self.buffers, i)
			if not success then
				vim.notify("[streamline] Failed to remove buffer from list", vim.log.levels.ERROR)
				self:gather_buffers()
			end
			if self.active_buf and self.active_buf.id == id then
				self:set_active_buffer(nil)
			end
			if self.previous_buf and self.previous_buf.id == id then
				self:set_previous_buffer(nil)
			end
			return
		end
	end
end

function M:on_buffer_entered(id)
	if self.navigating then
		self.navigating = false
		local index = self:get_buffer_index_from_id(id)
		if index then
			self:set_active_buffer_by_index(index)
		end
		return
	end

	if vim.api.nvim_buf_is_valid(id) then
		self:set_previous_buffer(self:get_active_buffer())
		local index = self:get_buffer_index_from_id(id)
		if index then
			self:set_active_buffer_by_index(index)
		end
	end
end

function M:set_active_buffer(buf)
	self.active_buf = buf
end

function M:set_active_buffer_by_index(index)
	local buf = nil
	for _, b in ipairs(self.buffers) do
		if b.index == index then
			buf = b
			break
		end
	end
	self:set_active_buffer(buf)
end

function M:get_active_buffer()
	return self.active_buf
end

function M:get_previous_buffer()
	return self.previous_buf
end

function M:set_previous_buffer(buf)
	self.previous_buf = buf
end

function M:navigate_backward()
	if self:get_active_buffer() == nil then
		return
	end

	local index = self:get_buffer_index_from_id(self:get_active_buffer().id)
	if index == 1 then
		self:navigate_to_index(#self.buffers)
	elseif index > 1 then
		self:navigate_to_index(index - 1)
	end
end

function M:navigate_forward()
	if self:get_active_buffer() == nil then
		return
	end

	local index = self:get_buffer_index_from_id(self:get_active_buffer().id)
	if index == #self.buffers then
		self:navigate_to_index(1)
	elseif index < #self.buffers then
		self:navigate_to_index(index + 1)
	end
end

function M:navigate_to_index(index)
	if not index or index < 1 or index > #self.buffers then
		return
	end

	local new_buf = self.buffers[index]
	if not new_buf then
		return
	end

	self.navigating = true

	if self.active_buf and self.active_buf.id ~= new_buf.id then
		self:set_previous_buffer(self.active_buf)
	end

	self.active_buf = new_buf
	vim.api.nvim_set_current_buf(new_buf.id)
end

function M:navigate_to_previous()
	if not self.previous_buf or not vim.api.nvim_buf_is_valid(self.previous_buf.id) then
		vim.notify("[streamline] No previous buffer to switch to", vim.log.levels.WARN)
		return
	end

	local prev_index = self:get_buffer_index_from_id(self.previous_buf.id)
	if prev_index then
		self:navigate_to_index(prev_index)
	else
		vim.notify("[streamline] Previous buffer no longer in list", vim.log.levels.WARN)
	end
end

function M:teardown()
	if self.augroup then
		vim.api.nvim_del_augroup_by_id(self.augroup)
		self.augroup = nil
	end
	if debounce_timer then
		local success, err = pcall(function()
			debounce_timer:close()
		end)
		if not success then
			vim.notify("[streamline] Failed to close debounce timer: " .. tostring(err), vim.log.levels.ERROR)
		end
		debounce_timer = nil
	end
end
return M
