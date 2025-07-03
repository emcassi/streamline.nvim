local M = {}

local core = require("streamline.core.core")
local config = core.config

function M:update_indices()
	for i, buf_id in ipairs(core.buffer_order) do
		if core.buffers[buf_id] then
			core.buffers[buf_id].index = i
		end
	end

	if core.active_buf then
		core.active_buf = core:get_buffer_by_id(core:get_active_buf().id)
	end
	if core.previous_buf then
		core.previous_buf = core:get_buffer_by_id(core:get_previous_buf().id)
	end
end

function M:on_buffer_modified(buf_id, is_modified)
	if core.buffers[buf_id] then
		core.get_buffer_by_id(buf_id).modified = is_modified
	end
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
		index = #core:get_buffer_order() + 1,
	}
end

function M:get_buffers()
	local list = {}
	for _, id in ipairs(core:get_buffer_order()) do
		if self.buffers[id] then
			table.insert(list, self.buffers[id])
		end
	end
	return list
end

function M:gather_buffers()
	core:clear_buffers()

	local success, buf_list = pcall(vim.api.nvim_list_bufs)
	if not success then
		vim.notify("[streamline] Failed to get buffer list", vim.log.levels.ERROR)
		self:teardown()
		return
	end

	for _, buf_id in ipairs(buf_list) do
		if vim.api.nvim_buf_is_valid(buf_id) then
			local bt = vim.bo[buf_id].buftype
			if not vim.tbl_contains(core.ignore_buftypes, bt) then
				local new_buf = self:create_buffer_entry(buf_id)
				if new_buf then
					core:set_active_buffer_by_index(new_buf.index)
					table.insert(core.buffer_order, buf_id)
					core.buffers[buf_id] = new_buf
				end
			end
		end
	end
	self:update_indices()
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

function M:on_buffer_added(buf_id)
	local bt = vim.bo[buf_id].buftype
	if core:should_ignore_buftype(bt) then
		return
	end

	local new_buf = self:create_buffer_entry(buf_id)
	if new_buf then
		core:set_buffer(buf_id, new_buf)
		if config.default_insert_behavior == "beginning" then
			core:insert_buffer_at_index(new_buf, 1)
		elseif config.default_insert_behavior == "end" then
			core:insert_buffer_at_end(new_buf)
		elseif config.default_insert_behavior == "before" then
			local target_index = core.active_buf and core.active_buf.index or 1
			core:insert_buffer_at_index(new_buf, target_index)
		elseif config.default_insert_behavior == "after" then
			local target_index = core.active_buf and core.active_buf.index + 1 or #core.buffer_order + 1
			core:insert_buffer_at_index(new_buf, target_index)
		end
		self:update_indices()
	end
end

function M:get_buffer(buf_id)
	return core:get_buffer_by_id(buf_id)
end

function M:get_buffer_at_index(index)
	local buf_id = core:get_buffer_order()[index]
	return buf_id and core:get_buffer_by_id(buf_id) or nil
end

function M:get_active_index()
	return core:get_active_buf() and core:get_active_buf().index or nil
end

function M:clean_empty_buffers()
	for i = #core.buffer_order, 1, -1 do
		local buf_id = core.buffer_order[i]
		if is_empty_modified_buffer(buf_id) then
			core:set_buffer(buf_id, nil)
			table.remove(core.buffers, i)
		end
	end
end

function M:on_buffer_removed(id)
	if core.buffers[id] then
		local index = core:get_buffer_by_id(id).index
		core:remove_buffer_at_index(index)

		if core.active_buf and core.active_buf.id == id then
			core.previous_buf = core.active_buf
			core.active_buf = nil
		end

		if core.previous_buf and core.previous_buf.id == id then
			core.previous_buf = nil
		end

		self:update_indices()
	end
end

function M:on_buffer_entered(id)
	if core:get_is_navigating() then
		core:set_is_navigating(false)
	end

	local success, is_valid = pcall(vim.api.nvim_buf_is_valid, id)
	if success and is_valid and core:get_buffer_by_id(id) ~= nil then
		local buf = core.buffers[id]
		if core.active_buf and core.active_buf.id ~= id then
			core.previous_buf = core.active_buf
		elseif not core.active_buf then
			core.active_buf = nil
		end

		buf.index = core:get_buffer_by_id(id).index
		core:set_active_buffer(buf)
	end
end

function M:teardown()
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
