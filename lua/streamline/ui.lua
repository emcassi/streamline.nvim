local M = {}

function M:print_buffers()
	local message = ""
	local core = require("streamline.core")
	local active_idx = core:get_active_index()
	if active_idx then
		message = string.format("Active buffer: %d/%d\n", active_idx, #core.buffers)
	end

	for i, buf in ipairs(core.buffers) do
		local active_marker = (buf.id == core.active) and "->" or ""
		local modified_marker = buf.modified and "* " or ""
		message = message
			.. string.format("%s %-3d [%2d] %-40s %s\n", active_marker, i, buf.id, buf.display_name, modified_marker)
	end

	if message == "" then
		message = "No buffers open"
	end
	vim.notify(message, vim.log.levels.INFO)
end

return M
