local M = {}

local core = require("streamline.core.core")
local buffer_state = require("streamline.core.buffer_state")

function M:reinsert_buffer_before_index(buf_index, target_buf_index)
	if buf_index == target_buf_index then
		return
	end

	if not core:get_buffer_order()[buf_index] or not core:get_buffer_order()[target_buf_index] then
		return
	end

	local buf_id = core:get_buffer_order()[buf_index]

	table.remove(core:get_buffer_order(), buf_index)

	local new_index = target_buf_index > buf_index and target_buf_index - 1 or target_buf_index
	new_index = math.max(1, math.min(new_index, core:get_num_buffers() + 1))

	table.insert(core:get_buffer_order(), new_index, buf_id)
	buffer_state:update_indices()
end

function M:reinsert_buffer_after_index(buf_index, target_buf_index)
	if buf_index == target_buf_index then
		return
	end

	if not core:get_buffer_order()[buf_index] or not core:get_buffer_order()[target_buf_index] then
		return
	end

	local buf_id = core.buffer_order[buf_index]
	local new_index = target_buf_index + 1
	if new_index > core:get_num_buffers() then
		new_index = core:get_num_buffers()
	end

	table.remove(core:get_buffer_order(), buf_index)
	table.insert(core:get_buffer_order(), new_index, buf_id)
	buffer_state:update_indices()
end

function M:reinsert_buffer_before_id(buf_id, target_buf_id)
	if core:get_buffer_by_id(buf_id) and core:get_buffer_by_id(target_buf_id) then
		self:reinsert_buffer_before_index(core.buffers[buf_id].index, core.buffers[target_buf_id].index)
	end
end

function M:reinsert_buffer_after_id(buf_id, target_buf_id)
	if core:get_buffer_by_id(buf_id) and core:get_buffer_by_id(target_buf_id) then
		self:reinsert_buffer_after_index(core.buffers[buf_id].index, core.buffers[target_buf_id].index)
	end
end

function M:swap_buffer_before()
	if not core:get_active_buf() then
		return
	end

	local current_index = core.active_buf.index
	local target_index = current_index - 1

	if target_index == 0 then
		target_index = core:get_num_buffers()
	end

	self:swap_buffer_with(current_index, target_index)
end

function M:swap_buffer_after()
	if not core:get_active_buf() then
		return
	end

	local current_index = core:get_active_buf().index
	local target_index = current_index + 1

	if target_index > core:get_num_buffers() then
		target_index = 1
	end

	self:swap_buffer_with(current_index, target_index)
end

function M:swap_buffer_with(buf_index, target_buf_index)
	if buf_index == target_buf_index then
		return
	end

	if not core:get_buffer_order()[buf_index] or not core:get_buffer_order()[target_buf_index] then
		return
	end

	local buf_id = core.buffer_order[buf_index]
	local target_buf_id = core.buffer_order[target_buf_index]

	core:get_buffer_order()[buf_index] = target_buf_id
	core:get_buffer_order()[target_buf_index] = buf_id

	core.active_buf = core.buffers[core:get_active_buf().id]
	core.previous_buf = core.buffers[core:get_previous_buf().id]

	buffer_state:update_indices()
end

return M
