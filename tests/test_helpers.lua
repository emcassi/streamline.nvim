local M = {}
local created_buffers = {}

function M.add_buffer(name_prefix)
	local buf_id = vim.api.nvim_create_buf(true, false)
	-- Unique name with prefix and clock timestamp
	local unique_name = name_prefix .. os.clock() .. ".txt"
	vim.api.nvim_buf_set_name(buf_id, unique_name)
	return buf_id
end

function M.reset_for_test(core)
	core.buffers = {}
	core.buffer_order = {}
	core.active_buf = nil
	core.previous_buf = nil

	for _, buf_id in ipairs(created_buffers) do
		if vim.api.nvim_buf_is_valid(buf_id) then
			vim.api.nvim_buf_delete(buf_id, { force = true })
		end
	end
	created_buffers = {}
end

function M.track_buffer(buf_id)
	table.insert(created_buffers, buf_id)
end

return M
