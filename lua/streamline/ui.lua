local M = {}

function M:print_buffers()
	local message = ""
	local core = require("streamline.core.core")
	local active_buf = core:get_active_buf()
	local previous_buf = core:get_previous_buf()

	local buffer_order = core.buffer_order
	local buffers = core.buffers

	if active_buf then
		local active_index = active_buf.index
		message = string.format("Active buffer: %d/%d\n", active_index or 0, #buffer_order)
	end

	if previous_buf then
		local prev_index = previous_buf.index
		message = message .. string.format("Previous buffer: %d/%d\n", prev_index or 0, #buffer_order)
	end

	for i, buf_id in ipairs(buffer_order) do
		local buf = buffers[buf_id]
		if buf then
			local active_marker = (active_buf and buf.id == active_buf.id) and "> " or ""
			local previous_marker = (previous_buf and buf.id == previous_buf.id) and "~ " or ""
			local modified_marker = buf.modified and "* " or ""

			message = message
				.. string.format(
					"%s%s %-3d [%2d] %-40s %s\n",
					active_marker,
					previous_marker,
					i,
					buf.id,
					buf.display_name,
					modified_marker
				)
		end
	end

	if message == "" then
		message = "No buffers open"
	end
	vim.notify(message, vim.log.levels.INFO)
end

return M
