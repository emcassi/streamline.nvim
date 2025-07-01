local M = {}

function M:print_buffers()
	local message = ""
	local core = require("streamline.core")
	local active_buf = core.active_buf
	local previous_buf = core.previous_buf

	if active_buf and active_buf.index then
		message = string.format("Active buffer: %d/%d\n", active_buf.index, #core.buffers)
	end

	if previous_buf and previous_buf.index then
		message = message .. string.format("Previous buffer: %d/%d\n", previous_buf.index, #core.buffers)
	end

	for i, buf in ipairs(core.buffers) do
		local active_marker = ""
		local previous_marker = ""

		if active_buf then
			active_marker = (buf.id == active_buf.id) and "> " or ""
		end
		if previous_buf then
			previous_marker = (buf.id == previous_buf.id) and "~ " or ""
		end
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

	if message == "" then
		message = "No buffers open"
	end
	vim.notify(message, vim.log.levels.INFO)
end

return M
