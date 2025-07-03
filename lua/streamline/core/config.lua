local M = {}

local core = require("streamline.core.core")
local navigation = require("streamline.core.navigation")
local reordering = require("streamline.core.reordering")

function M:setup_commands()
	vim.api.nvim_create_user_command("StreamBuffers", function()
		require("streamline.ui"):print_buffers()
	end, { desc = "Print current buffer list" })

	vim.api.nvim_create_user_command("StreamNavBackward", function()
		navigation:navigate_backward()
	end, { desc = "Navigate backward in buffer list" })

	vim.api.nvim_create_user_command("StreamNavForward", function()
		navigation:navigate_forward()
	end, { desc = "Navigate forward in buffer list" })

	vim.api.nvim_create_user_command("StreamNavToPrevious", function()
		navigation:navigate_to_previous()
	end, { desc = "Navigate to previous buffer" })

	vim.api.nvim_create_user_command("StreamNavToIndex", function(args)
		local index = tonumber(args.args)
		if index then
			navigation:navigate_to_index(index)
		else
			vim.notify("[streamline] Invalid index", vim.log.levels.ERROR)
		end
	end, { desc = "Navigate to buffer at index", nargs = 1 })

	vim.api.nvim_create_user_command("StreamSwapBufferBefore", function()
		reordering:swap_buffer_before()
	end, { desc = "Swap buffer with previous buffer" })

	vim.api.nvim_create_user_command("StreamSwapBufferAfter", function()
		reordering:swap_buffer_after()
	end, { desc = "Swap buffer with next buffer" })

	vim.api.nvim_create_user_command("StreamSwapBufferWith", function(args)
		local buf_index = tonumber(args.args)
		if buf_index then
			reordering:swap_buffer_with(buf_index)
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
			reordering:reinsert_buffer_before_index(buf_index, target_buf_index)
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
			reordering:reinsert_buffer_after_index(buf_index, target_buf_index)
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
			reordering:reinsert_buffer_before_id(buf_id, target_buf_id)
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
			reordering:reinsert_buffer_after_id(buf_id, target_buf_id)
		else
			vim.notify("[streamline] Invalid buffer ids", vim.log.levels.ERROR)
		end
	end, { desc = "Re-insert buffer after id", nargs = "+" })
end

return M
