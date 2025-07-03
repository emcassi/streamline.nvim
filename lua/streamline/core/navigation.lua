local M = {}

local core = require("streamline.core.core")

function M:navigate_backward()
	if core.active_buf == nil then
		return
	end

	local index = core.active_buf.index
	if index == 1 then
		self:navigate_to_index(#core.buffer_order)
	elseif index > 1 then
		self:navigate_to_index(index - 1)
	end
end

function M:navigate_forward()
	if core.active_buf == nil then
		return
	end

	local index = core.active_buf.index
	if index == #core.buffer_order then
		self:navigate_to_index(1)
	elseif index < #core.buffer_order then
		self:navigate_to_index(index + 1)
	end
end

function M:navigate_to_index(index)
	if not index or index < 1 or index > #core.buffer_order then
		return
	end

	local new_buf_id = core.buffer_order[index]
	if not new_buf_id then
		return
	end

	core.navigating = true

	if core.active_buf and core.active_buf.id ~= new_buf_id then
		core.previous_buf = core.active_buf
	end

	local new_buf = core.buffers[new_buf_id]
	core.active_buf = new_buf
	core.active_buf.index = index
	vim.api.nvim_set_current_buf(new_buf_id)
end

function M:navigate_to_previous()
	if not core.previous_buf or not vim.api.nvim_buf_is_valid(core.previous_buf.id) then
		vim.notify("[streamline] No previous buffer to switch to", vim.log.levels.WARN)
		return
	end

	local prev_index = core.previous_buf.index
	if prev_index then
		self:navigate_to_index(prev_index)
	else
		vim.notify("[streamline] Previous buffer no longer in list", vim.log.levels.WARN)
	end
end

return M
