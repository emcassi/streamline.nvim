local it = require("plenary.busted").it
local describe = require("plenary.busted").describe
local created_buffers = {}

local function add_buffer(name)
	local buf_id = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_create_buf(true, false)
	assert.is_true(vim.api.nvim_buf_is_valid(buf_id))
	vim.api.nvim_buf_set_name(buf_id, name)
	return buf_id
end

describe("Streamline buffer management", function()
	local core = require("streamline.core")

	before_each(function()
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
	end)

	it("adds a buffer to the list", function()
		local buf_id = vim.api.nvim_create_buf(true, false)
		table.insert(created_buffers, buf_id)

		assert.is_true(vim.api.nvim_buf_is_valid(buf_id))

		vim.api.nvim_buf_set_name(buf_id, "test.lua")
		core:on_buffer_added(buf_id)

		assert.is_true(core.buffers[buf_id] ~= nil)
		assert.is_true(vim.tbl_contains(core.buffer_order, buf_id))
	end)

	it("adds a scratch buffer to the list", function()
		local buf_id = vim.api.nvim_create_buf(false, true)
		table.insert(created_buffers, buf_id)

		assert.is_true(vim.api.nvim_buf_is_valid(buf_id))

		vim.api.nvim_buf_set_name(buf_id, "test.lua")
		core:on_buffer_added(buf_id)

		assert.is_true(core.buffers[buf_id] == nil)
		assert.is_false(vim.tbl_contains(core.buffer_order, buf_id))
	end)

	it("deletes the only buffer in the list", function()
		local buf_id = vim.api.nvim_create_buf(true, false)
		table.insert(created_buffers, buf_id)
		assert.is_true(vim.api.nvim_buf_is_valid(buf_id))

		vim.api.nvim_buf_set_name(buf_id, "test.lua")
		core:on_buffer_removed(buf_id)

		assert.is_true(core.buffers[buf_id] == nil)
		assert.is_false(vim.tbl_contains(core.buffer_order, buf_id))
	end)

	it("deletes the active buffer in a list", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		local buf3_id = add_buffer("test3.lua")
		table.insert(created_buffers, buf3_id)

		local buf2 = core.buffers[buf2_id]
		core.active_buf = buf2

		core:on_buffer_removed(core.active_buf)

		assert.is_true(core.buffers[buf2_id] == nil)
		assert.is_false(vim.tbl_contains(core.buffer_order, buf2_id))
	end)

	it("insert a second buffer into the list from index 1, behavior = beginning", function()
		core.config.default_insert_behavior = "beginning"
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)

		assert.is_true(core.buffers[buf2_id] ~= nil)
		assert.is_true(core.buffer_order[1] == buf2_id)
		assert.is_true(core.buffers[buf2_id].index == 1)
	end)

	it("inserts a third buffer into the list from index 1, behavior = beginning", function()
		core.config.default_insert_behavior = "beginning"
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)

		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		core:on_buffer_entered(buf1_id)

		local buf3_id = add_buffer("test3.lua")
		table.insert(created_buffers, buf3_id)
		core:on_buffer_added(buf3_id)
		core:on_buffer_entered(buf3_id)

		assert.is_true(core.buffers[buf3_id] ~= nil)
		assert.is_true(vim.tbl_contains(core.buffer_order, buf3_id))
		assert.is_true(core.buffers[buf3_id].index == 1)
	end)

	it("insert a second buffer into the list from index 1, behavior = end", function()
		core.config.default_insert_behavior = "end"
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)

		assert.is_true(core.buffers[buf2_id] ~= nil)
		assert.is_true(core.buffer_order[2] == buf2_id)
		assert.is_true(core.buffers[buf2_id].index == 2)
	end)

	it("inserts a third buffer into the list from index 1, behavior = end", function()
		core.config.default_insert_behavior = "end"
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)

		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		core:on_buffer_entered(buf1_id)

		local buf3_id = add_buffer("test3.lua")
		table.insert(created_buffers, buf3_id)
		core:on_buffer_added(buf3_id)
		core:on_buffer_entered(buf3_id)

		assert.is_true(core.buffers[buf3_id] ~= nil)
		assert.is_true(core.buffer_order[3] == buf3_id)
		assert.is_true(vim.tbl_contains(core.buffer_order, buf3_id))
		assert.is_true(core.active_buf.index == 3)
	end)

	it("insert a second buffer into the list from index 1, behavior = before", function()
		core.config.default_insert_behavior = "before"
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)

		assert.is_true(core.buffers[buf2_id] ~= nil)
		assert.is_true(core.buffer_order[1] == buf2_id)
		assert.is_true(core.buffers[buf2_id].index == 1)
	end)

	it("inserts a third buffer into the list from index 1, behavior = before", function()
		core.config.default_insert_behavior = "before"
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)

		core:on_buffer_added(buf1_id) -- <test1.lua>
		core:on_buffer_entered(buf1_id)

		core:on_buffer_added(buf2_id) -- <test2.lua><test1.lua>
		core:on_buffer_entered(buf2_id)

		core:on_buffer_entered(buf2_id)

		local buf3_id = add_buffer("test3.lua")
		table.insert(created_buffers, buf3_id)
		core:on_buffer_added(buf3_id) -- <test3.lua><test2.lua><test1.lua>
		core:on_buffer_entered(buf3_id)

		assert.is_true(core.buffers[buf3_id] ~= nil)
		assert.is_true(vim.tbl_contains(core.buffer_order, buf3_id))
		assert.is_true(core.buffer_order[1] == buf3_id)
		assert.is_true(core.active_buf.index == 1)
	end)

	it("inserts a third buffer into the list from index 2, behavior = before", function()
		core.config.default_insert_behavior = "after"
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)

		core:on_buffer_added(buf1_id) -- <test1.lua>
		core:on_buffer_entered(buf1_id)

		core:on_buffer_added(buf2_id) -- <test2.lua><test1.lua>
		core:on_buffer_entered(buf2_id)

		core:on_buffer_entered(buf1_id)

		local buf3_id = add_buffer("test3.lua")
		table.insert(created_buffers, buf3_id)
		core:on_buffer_added(buf3_id) -- <test2.lua><test3.lua><test1.lua>
		core:on_buffer_entered(buf3_id)

		assert.is_true(core.buffers[buf3_id] ~= nil)
		assert.is_true(vim.tbl_contains(core.buffer_order, buf3_id))
		assert.is_true(core.buffer_order[2] == buf3_id)
		assert.is_true(core.active_buf.index == 2)
	end)

	it("insert a second buffer into the list from index 1, behavior = after", function()
		core.config.default_insert_behavior = "after"
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id) -- <test1.lua>

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id) -- <test1.lua><test2.lua>

		assert.is_true(core.buffers[buf2_id] ~= nil)
		assert.is_true(core.buffer_order[2] == buf2_id)
		assert.is_true(core.buffers[buf2_id].index == 2)
	end)

	it("inserts a third buffer into the list from index 1, behavior = after", function()
		core.config.default_insert_behavior = "after"
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)

		core:on_buffer_added(buf1_id) -- <test1.lua>
		core:on_buffer_entered(buf1_id)

		core:on_buffer_added(buf2_id) -- <test1.lua><test2.lua>
		core:on_buffer_entered(buf2_id)

		core:on_buffer_entered(buf1_id)

		local buf3_id = add_buffer("test3.lua")
		table.insert(created_buffers, buf3_id)
		core:on_buffer_added(buf3_id) -- <test1.lua><test3.lua><test2.lua>
		core:on_buffer_entered(buf3_id)

		assert.is_true(core.buffers[buf3_id] ~= nil)
		assert.is_true(vim.tbl_contains(core.buffer_order, buf3_id))
		assert.is_true(core.buffer_order[2] == buf3_id)
		assert.is_true(core.active_buf.index == 2)
	end)

	it("inserts a third buffer into the list from index 2, behavior = after", function()
		core.config.default_insert_behavior = "after"
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)

		core:on_buffer_added(buf1_id) -- <test1.lua>
		core:on_buffer_entered(buf1_id)

		core:on_buffer_added(buf2_id) -- <test1.lua><test2.lua>
		core:on_buffer_entered(buf2_id)

		core:on_buffer_entered(buf2_id)

		local buf3_id = add_buffer("test3.lua")
		table.insert(created_buffers, buf3_id)
		core:on_buffer_added(buf3_id) -- <test1.lua><test2.lua><test3.lua>
		core:on_buffer_entered(buf3_id)

		assert.is_true(core.buffers[buf3_id] ~= nil)
		assert.is_true(vim.tbl_contains(core.buffer_order, buf3_id))
		assert.is_true(core.buffer_order[3] == buf3_id)
		assert.is_true(core.active_buf.index == 3)
	end)

	it("go to the buffer before the current in the list of 2", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		core:navigate_backward()

		assert.is_equal(core.active_buf.id, buf1_id)
	end)

	it("go to the buffer before the current in the list of 3", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		local buf3_id = add_buffer("test3.lua")
		table.insert(created_buffers, buf3_id)
		core:on_buffer_added(buf3_id)
		core:on_buffer_entered(buf3_id)

		core:navigate_backward()

		assert.is_equal(core.active_buf.id, buf2_id)
	end)

	it("navigation wraps around the list going backwards", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		local buf3_id = add_buffer("test3.lua")
		table.insert(created_buffers, buf3_id)
		core:on_buffer_added(buf3_id)
		core:on_buffer_entered(buf3_id)

		core:navigate_backward()
		core:navigate_backward()
		core:navigate_backward()

		assert.is_equal(core.active_buf.id, buf3_id)
	end)

	it("go to the buffer after the current in the list of 2", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		core:on_buffer_entered(buf1_id)

		core:navigate_forward()

		assert.is_equal(core.active_buf.id, buf2_id)
	end)

	it("go to the buffer after the current in the list of 3", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		local buf3_id = add_buffer("test3.lua")
		table.insert(created_buffers, buf3_id)
		core:on_buffer_added(buf3_id)
		core:on_buffer_entered(buf3_id)

		core:on_buffer_entered(buf2_id)

		core:navigate_forward()

		assert.is_equal(core.active_buf.id, buf3_id)
	end)

	it("navigation wraps around the list going forwards", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		local buf3_id = add_buffer("test3.lua")
		table.insert(created_buffers, buf3_id)
		core:on_buffer_added(buf3_id)
		core:on_buffer_entered(buf3_id)

		core:navigate_forward()
		core:navigate_forward()
		core:navigate_forward()

		assert.is_equal(core.active_buf.id, buf3_id)
	end)

	it("go to the previous buffer in a list of 1", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		core:navigate_to_previous() -- no previous buffer

		assert.is_equal(core.active_buf.id, buf1_id)
	end)

	it("go to the previous buffer in a list of 2", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)
		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		core:navigate_to_previous() -- previous buffer should be buf1

		assert.is_equal(core.active_buf.id, buf1_id)
	end)

	it("go to the previous buffer in a list of 3", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)
		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)
		local buf3_id = add_buffer("test3.lua")
		table.insert(created_buffers, buf3_id)
		core:on_buffer_added(buf3_id)
		core:on_buffer_entered(buf3_id)

		core:on_buffer_entered(buf1_id)

		core:navigate_to_previous() -- previous buffer should be buf1

		assert.is_equal(core.active_buf.id, buf3_id)
	end)

	it("swap buffers at index 1 and 2 in a list of 2", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)
		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		core:swap_buffer_with(1, 2)

		assert.is_equal(core.active_buf.id, buf2_id)
		assert.is_equal(core.buffer_order[1], buf2_id)
		assert.is_equal(core.buffer_order[2], buf1_id)
	end)

	it("swap buffers at index 1 and 3 in a list of 3", function()
		core.config.default_insert_behavior = "end"

		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)
		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)
		local buf3_id = add_buffer("test3.lua")
		table.insert(created_buffers, buf3_id)
		core:on_buffer_added(buf3_id)
		core:on_buffer_entered(buf3_id)

		core:swap_buffer_with(1, 3)

		assert.is_equal(core.active_buf.id, buf3_id)
		assert.is_equal(core.buffer_order[1], buf3_id)
		assert.is_equal(core.buffer_order[2], buf2_id)
		assert.is_equal(core.buffer_order[3], buf1_id)
	end)

	it("reinsert a buffer at index 1 before index 2 in a list of 2", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		core:reinsert_buffer_before_index(1, 2)

		assert.is_equal(core.active_buf.id, buf2_id)
		assert.is_equal(core.buffer_order[1], buf1_id)
		assert.is_equal(core.buffer_order[2], buf2_id)
	end)

	it("reinsert a buffer at index 2 before index 1 in a list of 2", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		core:reinsert_buffer_before_index(2, 1)

		assert.is_equal(core.active_buf.id, buf2_id)
		assert.is_equal(core.buffer_order[1], buf2_id)
		assert.is_equal(core.buffer_order[2], buf1_id)
	end)

	it("reinsert a buffer at index 3 before index 2 in a list of 3", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		local buf3_id = add_buffer("test3.lua")
		table.insert(created_buffers, buf3_id)
		core:on_buffer_added(buf3_id)
		core:on_buffer_entered(buf3_id)

		core:reinsert_buffer_before_index(3, 2)

		assert.is_equal(core.active_buf.id, buf3_id)
		assert.is_equal(core.buffer_order[1], buf1_id)
		assert.is_equal(core.buffer_order[2], buf3_id)
		assert.is_equal(core.buffer_order[3], buf2_id)
	end)

	it("reinsert a buffer at index 2 after index 1 in a list of 2", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		core:reinsert_buffer_after_index(2, 1)

		assert.is_equal(core.active_buf.id, buf2_id)
		assert.is_equal(core.buffer_order[1], buf1_id)
		assert.is_equal(core.buffer_order[2], buf2_id)
	end)

	it("reinsert a buffer at index 1 after index 2 in a list of 2", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		core:reinsert_buffer_after_index(1, 2)

		assert.is_equal(core.active_buf.id, buf2_id)
		assert.is_equal(core.buffer_order[1], buf2_id)
		assert.is_equal(core.buffer_order[2], buf1_id)
	end)

	it("reinsert a buffer at index 1 after index 2 in a list of 3", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		local buf3_id = add_buffer("test3.lua")
		table.insert(created_buffers, buf3_id)
		core:on_buffer_added(buf3_id)
		core:on_buffer_entered(buf3_id)

		core:reinsert_buffer_after_index(1, 2)

		assert.is_equal(core.active_buf.id, buf3_id)
		assert.is_equal(core.buffer_order[1], buf2_id)
		assert.is_equal(core.buffer_order[2], buf3_id)
		assert.is_equal(core.buffer_order[3], buf1_id)
	end)

	it("reinsert a buffer at index 1 before index 2 in a list of 2 by id", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		core:reinsert_buffer_before_id(buf1_id, buf2_id)

		assert.is_equal(core.active_buf.id, buf2_id)
		assert.is_equal(core.buffer_order[1], buf1_id)
		assert.is_equal(core.buffer_order[2], buf2_id)
	end)

	it("reinsert a buffer at index 2 before index 1 in a list of 2 by id", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		core:reinsert_buffer_before_id(buf2_id, buf1_id)

		assert.is_equal(core.active_buf.id, buf2_id)
		assert.is_equal(core.buffer_order[1], buf2_id)
		assert.is_equal(core.buffer_order[2], buf1_id)
	end)

	it("reinsert a buffer at index 3 before index 2 in a list of 3 by id", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		local buf3_id = add_buffer("test3.lua")
		table.insert(created_buffers, buf3_id)
		core:on_buffer_added(buf3_id)
		core:on_buffer_entered(buf3_id)

		core:reinsert_buffer_before_id(buf3_id, buf2_id)

		assert.is_equal(core.active_buf.id, buf3_id)
		assert.is_equal(core.buffer_order[1], buf1_id)
		assert.is_equal(core.buffer_order[2], buf3_id)
		assert.is_equal(core.buffer_order[3], buf2_id)
	end)

	it("reinsert a buffer at index 2 after index 1 in a list of 2 by id", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		core:reinsert_buffer_after_id(buf2_id, buf1_id)

		assert.is_equal(core.active_buf.id, buf2_id)
		assert.is_equal(core.buffer_order[1], buf1_id)
		assert.is_equal(core.buffer_order[2], buf2_id)
	end)

	it("reinsert a buffer at index 1 after index 2 in a list of 2 by id", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		core:reinsert_buffer_after_id(buf1_id, buf2_id)

		assert.is_equal(core.active_buf.id, buf2_id)
		assert.is_equal(core.buffer_order[1], buf2_id)
		assert.is_equal(core.buffer_order[2], buf1_id)
	end)

	it("reinsert a buffer at index 1 after index 2 in a list of 3 by id", function()
		local buf1_id = add_buffer("test1.lua")
		table.insert(created_buffers, buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		table.insert(created_buffers, buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		local buf3_id = add_buffer("test3.lua")
		table.insert(created_buffers, buf3_id)
		core:on_buffer_added(buf3_id)
		core:on_buffer_entered(buf3_id)

		core:reinsert_buffer_after_id(buf1_id, buf2_id)

		assert.is_equal(core.active_buf.id, buf3_id)
		assert.is_equal(core.buffer_order[1], buf2_id)
		assert.is_equal(core.buffer_order[2], buf3_id)
		assert.is_equal(core.buffer_order[3], buf1_id)
	end)
end)
