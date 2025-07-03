local M = {
	buffers = {},
	buffer_order = {},
	active_buf = nil,
	previous_buf = nil,
	ignore_buftypes = { "quickfix", "nofile" },
	navigating = false,
	config = {
		default_insert_behavior = "end",
	},
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

	vim.api.nvim_create_user_command("StreamSwapBufferBefore", function()
		m:swap_buffer_before()
	end, { desc = "Swap buffer with previous buffer" })

	vim.api.nvim_create_user_command("StreamSwapBufferAfter", function()
		m:swap_buffer_after()
	end, { desc = "Swap buffer with next buffer" })

	vim.api.nvim_create_user_command("StreamSwapBufferWith", function(args)
		local buf_index = tonumber(args.args)
		if buf_index then
			m:swap_buffer_with(buf_index)
		else
			vim.notify("[streamline] Invalid buffer id", vim.log.levels.ERROR)
		end
	end, { desc = "Swap buffer with buffer at index", nargs = 1 })

	vim.api.nvim_create_user_command("StreamReinsertBufferBeforeIndex", function(args)
		local fargs = args.fargs
		if #fargs < 2 then
			vim.notify("[streamline] Expected two arguments: current_index target_index", vim.log.levels.ERROR)
			return
		end

		local buf_index = tonumber(fargs[1])
		local target_buf_index = tonumber(fargs[2])

		if buf_index and target_buf_index then
			m:reinsert_buffer_before_index(buf_index, target_buf_index)
		else
			vim.notify("[streamline] Invalid buffer indexes", vim.log.levels.ERROR)
		end
	end, {
		desc = "Re-insert buffer before index",
		nargs = "+",
	})

	vim.api.nvim_create_user_command("StreamReinsertBufferAfterIndex", function(args)
		local fargs = args.fargs or {}
		if #fargs < 2 then
			vim.notify("[streamline] Expected two arguments: current_index target_index", vim.log.levels.ERROR)
			return
		end

		local buf_index = tonumber(fargs[1])
		local target_buf_index = tonumber(fargs[2])

		if buf_index and target_buf_index then
			m:reinsert_buffer_after_index(buf_index, target_buf_index)
		else
			vim.notify("[streamline] Invalid buffer indexes", vim.log.levels.ERROR)
		end
	end, { desc = "Re-insert buffer after index", nargs = "+" })

	vim.api.nvim_create_user_command("StreamReinsertBufferBeforeById", function(args)
		local fargs = args.fargs or {}
		if #fargs < 2 then
			vim.notify("[streamline] Expected two arguments: current_id target_id", vim.log.levels.ERROR)
			return
		end

		local buf_id = tonumber(fargs[1])
		local target_buf_id = tonumber(fargs[2])

		if buf_id and target_buf_id then
			m:reinsert_buffer_before_id(buf_id, target_buf_id)
		else
			vim.notify("[streamline] Invalid buffer ids", vim.log.levels.ERROR)
		end
	end, {
		desc = "Re-insert buffer before id",
		nargs = "+",
	})

	vim.api.nvim_create_user_command("StreamReinsertBufferAfterById", function(args)
		local fargs = args.fargs or {}
		if #fargs < 2 then
			vim.notify("[streamline] Expected two arguments: current_id target_id", vim.log.levels.ERROR)
			return
		end

		local buf_id = tonumber(fargs[1])
		local target_buf_id = tonumber(fargs[2])

		if buf_id and target_buf_id then
			m:reinsert_buffer_after_id(buf_id, target_buf_id)
		else
			vim.notify("[streamline] Invalid buffer ids", vim.log.levels.ERROR)
		end
	end, { desc = "Re-insert buffer after id", nargs = "+" })
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
	return self.buffers[buf_id]
end

function M:get_buffers()
	local list = {}
	for _, id in ipairs(self.buffer_order) do
		if self.buffers[id] then
			table.insert(list, self.buffers[id])
		end
	end
	return list
end

function M:get_buffer_index_from_id(id)
	for i, buf_id in ipairs(self.buffer_order) do
		if buf_id == id then
			return i
		end
	end
	return nil
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

function M:create_buffer_entry(buf_id)
	local success, buf_name = pcall(vim.api.nvim_buf_get_name, buf_id)
	if not success then
		vim.notify("[streamline] Failed to get buffer name", vim.log.levels.ERROR)
		return nil
	end

	return {
		id = buf_id,
		name = buf_name,
		display_name = self:get_buffer_display_name(buf_id),
		modified = vim.bo[buf_id].modified,
		index = #self.buffer_order + 1,
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

local function update_indices(self)
	for i, buf_id in ipairs(self.buffer_order) do
		if self.buffers[buf_id] then
			self.buffers[buf_id].index = i
		end
	end

	if self.active_buf then
		self.active_buf = self.buffers[self.active_buf.id]
	end
	if self.previous_buf then
		self.previous_buf = self.buffers[self.previous_buf.id]
	end
end

function M:on_buffer_modified(buf_id, is_modified)
	if self.buffers[buf_id] then
		self.buffers[buf_id].modified = is_modified
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
	self.buffer_order = {}

	local success, buf_list = pcall(vim.api.nvim_list_bufs)
	if not success then
		vim.notify("[streamline] Failed to get buffer list", vim.log.levels.ERROR)
		self:teardown()
		return
	end

	for _, buf_id in ipairs(buf_list) do
		if vim.api.nvim_buf_is_valid(buf_id) then
			local bt = vim.bo[buf_id].buftype
			if not vim.tbl_contains(self.ignore_buftypes, bt) then
				local new_buf = self:create_buffer_entry(buf_id)
				if new_buf then
					self:set_active_buffer_by_index()
					table.insert(self.buffer_order, buf_id)
					self.buffers[buf_id] = new_buf
				end
			end
		end
	end
	update_indices(self)
end

function M:on_buffer_added(buf_id)
	local bt = vim.bo[buf_id].buftype
	if vim.tbl_contains(self.ignore_buftypes, bt) then
		return
	end

	local new_buf = self:create_buffer_entry(buf_id)
	if new_buf then
		self.buffers[buf_id] = new_buf
		if self.config.default_insert_behavior == "beginning" then
			table.insert(self.buffer_order, 1, buf_id)
		elseif self.config.default_insert_behavior == "end" then
			table.insert(self.buffer_order, buf_id)
		elseif self.config.default_insert_behavior == "before" then
			local target_index = self.active_buf and self:get_buffer_index_from_id(self.active_buf.id) or 1
			table.insert(self.buffer_order, target_index, buf_id)
		elseif self.config.default_insert_behavior == "after" then
			local target_index = self.active_buf and self:get_buffer_index_from_id(self.active_buf.id) + 1
				or #self.buffer_order + 1
			table.insert(self.buffer_order, target_index, buf_id)
		end
		update_indices(self)
	end
end

function M:has_buffer(id)
	return self:get_buffer_by_id(id) ~= nil
end

function M:get_buffer(buf_id)
	return self.buffers[buf_id]
end

function M:get_buffer_at_index(index)
	local buf_id = self.buffer_order[index]
	return buf_id and self.buffers[buf_id] or nil
end

function M:get_active_index()
	return self.active_buf and self.active_buf.index or nil
end

function M:clean_empty_buffers()
	for i = #self.buffer_order, 1, -1 do
		local buf_id = self.buffer_order[i]
		if is_empty_modified_buffer(buf_id) then
			self.buffers[buf_id] = nil
			table.remove(self.buffers, i)
		end
	end
end

function M:on_buffer_removed(id)
	if self.buffers[id] then
		local index = self:get_buffer_index_from_id(id)
		table.remove(self.buffer_order, index)
		self.buffers[id] = nil

		if self.active_buf and self.active_buf.id == id then
			self.previous_buf = self.active_buf
			self.active_buf = nil
		end

		if self.previous_buf and self.previous_buf.id == id then
			self.previous_buf = nil
		end

		update_indices(self)
	end
end

function M:on_buffer_entered(id)
	if self.navigating then
		self.navigating = false
	end

	local success, is_valid = pcall(vim.api.nvim_buf_is_valid, id)
	if success and is_valid and self.buffers[id] then
		local buf = self.buffers[id]
		if self.active_buf and self.active_buf.id ~= id then
			self.previous_buf = self.active_buf
		elseif not self.active_buf then
			self.active_buf = nil
		end

		buf.index = self:get_buffer_index_from_id(id)
		self:set_active_buffer(buf)
	end
end

function M:set_active_buffer(buf)
	self.active_buf = buf
end

function M:set_active_buffer_by_index(index)
	local buf_id = self.buffer_order[index]
	if buf_id then
		local buf = self.buffers[buf_id]
		self:set_active_buffer(buf)
	end
end

function M:navigate_backward()
	if self.active_buf == nil then
		return
	end

	local index = self:get_buffer_index_from_id(self.active_buf.id)
	if index == 1 then
		self:navigate_to_index(#self.buffer_order)
	elseif index > 1 then
		self:navigate_to_index(index - 1)
	end
end

function M:navigate_forward()
	if self.active_buf == nil then
		return
	end

	local index = self:get_buffer_index_from_id(self.active_buf.id)
	if index == #self.buffer_order then
		self:navigate_to_index(1)
	elseif index < #self.buffer_order then
		self:navigate_to_index(index + 1)
	end
end

function M:navigate_to_index(index)
	if not index or index < 1 or index > #self.buffer_order then
		return
	end

	local new_buf_id = self.buffer_order[index]
	if not new_buf_id then
		return
	end

	self.navigating = true

	if self.active_buf and self.active_buf.id ~= new_buf_id then
		self.previous_buf = self.active_buf
	end

	local new_buf = self.buffers[new_buf_id]
	self.active_buf = new_buf
	self.active_buf.index = index
	vim.api.nvim_set_current_buf(new_buf_id)
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

function M:reinsert_buffer_before_index(buf_index, target_buf_index)
	if buf_index == target_buf_index then
		return
	end

	if not self.buffer_order[buf_index] then
		return
	end

	if not self.buffer_order[target_buf_index] then
		return
	end

	local buf_id = self.buffer_order[buf_index]

	local new_index = target_buf_index - 1
	if new_index < 1 then
		new_index = 1
	end

	table.remove(self.buffer_order, buf_index)
	table.insert(self.buffer_order, new_index, buf_id)
	update_indices(self)
end

function M:reinsert_buffer_after_index(buf_index, target_buf_index)
	if buf_index == target_buf_index then
		return
	end

	if not self.buffer_order[buf_index] then
		return
	end

	if not self.buffer_order[target_buf_index] then
		return
	end

	local buf_id = self.buffer_order[buf_index]
	local new_index = target_buf_index + 1
	if new_index > #self.buffer_order then
		new_index = #self.buffer_order
	end

	table.remove(self.buffer_order, buf_index)
	table.insert(self.buffer_order, new_index, buf_id)
	update_indices(self)
end

function M:reinsert_buffer_before_id(buf_id, target_buf_id)
	if self.buffers[buf_id] and self.buffers[target_buf_id] then
		self:reinsert_buffer_before_index(
			self:get_buffer_index_from_id(buf_id),
			self:get_buffer_index_from_id(target_buf_id)
		)
	end
end

function M:reinsert_buffer_after_id(buf_id, target_buf_id)
	if self.buffers[buf_id] and self.buffers[target_buf_id] then
		self:reinsert_buffer_after_index(
			self:get_buffer_index_from_id(buf_id),
			self:get_buffer_index_from_id(target_buf_id)
		)
	end
end

function M:swap_buffer_before()
	if not self.active_buf then
		return
	end

	local current_index = self:get_buffer_index_from_id(self.active_buf.id)
	local target_index = current_index - 1

	if target_index == 0 then
		target_index = #self.buffer_order
	end

	self:swap_buffer_with(current_index, target_index)
end

function M:swap_buffer_after()
	if not self.active_buf then
		return
	end

	local current_index = self:get_buffer_index_from_id(self.active_buf.id)
	local target_index = current_index + 1

	if target_index > #self.buffer_order then
		target_index = 1
	end

	self:swap_buffer_with(current_index, target_index)
end

function M:swap_buffer_with(buf_index, target_buf_index)
	if buf_index == target_buf_index then
		return
	end

	if not self.buffer_order[buf_index] then
		return
	end

	if not self.buffer_order[target_buf_index] then
		return
	end

	local buf_id = self.buffer_order[buf_index]
	local target_buf_id = self.buffer_order[target_buf_index]

	self.buffer_order[buf_index] = target_buf_id
	self.buffer_order[target_buf_index] = buf_id

	self.active_buf = self.buffers[self.active_buf.id]
	self.previous_buf = self.buffers[self.previous_buf.id]

	update_indices(self)
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
