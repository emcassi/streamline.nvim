local it = require("plenary.busted").it
local describe = require("plenary.busted").describe
local test_helpers = require("tests.test_helpers")
local add_buffer = test_helpers.add_buffer

describe("Streamline insert buffer behavior", function()
	local core = require("streamline.core.core")
	local buffer_state = require("streamline.core.buffer_state")

	before_each(function()
		test_helpers.reset_for_test(core)
	end)

	it("insert a second buffer into the list from index 1, behavior = beginning", function()
		core.config.default_insert_behavior = "beginning"
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		buffer_state:on_buffer_added(buf1_id)

		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		buffer_state:on_buffer_added(buf2_id)

		assert.is_true(core.buffers[buf2_id] ~= nil)
		assert.is_true(core.buffer_order[1] == buf2_id)
		assert.is_true(core.buffers[buf2_id].index == 1)
	end)

	it("inserts a third buffer into the list from index 1, behavior = beginning", function()
		core.config.default_insert_behavior = "beginning"
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)

		buffer_state:on_buffer_added(buf1_id)
		buffer_state:on_buffer_entered(buf1_id)

		buffer_state:on_buffer_added(buf2_id)
		buffer_state:on_buffer_entered(buf2_id)

		buffer_state:on_buffer_entered(buf1_id)

		local buf3_id = add_buffer("test3")
		test_helpers.track_buffer(buf3_id)
		buffer_state:on_buffer_added(buf3_id)
		buffer_state:on_buffer_entered(buf3_id)

		assert.is_true(core.buffers[buf3_id] ~= nil)
		assert.is_true(vim.tbl_contains(core.buffer_order, buf3_id))
		assert.is_true(core.buffers[buf3_id].index == 1)
	end)

	it("insert a second buffer into the list from index 1, behavior = end", function()
		core.config.default_insert_behavior = "end"
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		buffer_state:on_buffer_added(buf1_id)

		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		buffer_state:on_buffer_added(buf2_id)

		assert.is_true(core.buffers[buf2_id] ~= nil)
		assert.is_true(core.buffer_order[2] == buf2_id)
		assert.is_true(core.buffers[buf2_id].index == 2)
	end)

	it("inserts a third buffer into the list from index 1, behavior = end", function()
		core.config.default_insert_behavior = "end"
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)

		buffer_state:on_buffer_added(buf1_id)
		buffer_state:on_buffer_entered(buf1_id)

		buffer_state:on_buffer_added(buf2_id)
		buffer_state:on_buffer_entered(buf2_id)

		buffer_state:on_buffer_entered(buf1_id)

		local buf3_id = add_buffer("test3")
		test_helpers.track_buffer(buf3_id)
		buffer_state:on_buffer_added(buf3_id)
		buffer_state:on_buffer_entered(buf3_id)

		assert.is_true(core.buffers[buf3_id] ~= nil)
		assert.is_true(core.buffer_order[3] == buf3_id)
		assert.is_true(vim.tbl_contains(core.buffer_order, buf3_id))
		assert.is_true(core.active_buf.index == 3)
	end)

	it("insert a second buffer into the list from index 1, behavior = before", function()
		core.config.default_insert_behavior = "before"
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		buffer_state:on_buffer_added(buf1_id)

		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		buffer_state:on_buffer_added(buf2_id)

		assert.is_true(core.buffers[buf2_id] ~= nil)
		assert.is_true(core.buffer_order[1] == buf2_id)
		assert.is_true(core.buffers[buf2_id].index == 1)
	end)

	it("inserts a third buffer into the list from index 1, behavior = before", function()
		core.config.default_insert_behavior = "before"
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)

		buffer_state:on_buffer_added(buf1_id) -- <test1>
		buffer_state:on_buffer_entered(buf1_id)

		buffer_state:on_buffer_added(buf2_id) -- <test2><test1.lua>
		buffer_state:on_buffer_entered(buf2_id)

		buffer_state:on_buffer_entered(buf2_id)

		local buf3_id = add_buffer("test3")
		test_helpers.track_buffer(buf3_id)
		buffer_state:on_buffer_added(buf3_id) -- <test3><test2.lua><test1.lua>
		buffer_state:on_buffer_entered(buf3_id)

		assert.is_true(core.buffers[buf3_id] ~= nil)
		assert.is_true(vim.tbl_contains(core.buffer_order, buf3_id))
		assert.is_true(core.buffer_order[1] == buf3_id)
		assert.is_true(core.active_buf.index == 1)
	end)

	it("inserts a third buffer into the list from index 2, behavior = before", function()
		core.config.default_insert_behavior = "after"
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)

		buffer_state:on_buffer_added(buf1_id) -- <test1>
		buffer_state:on_buffer_entered(buf1_id)

		buffer_state:on_buffer_added(buf2_id) -- <test2><test1.lua>
		buffer_state:on_buffer_entered(buf2_id)

		buffer_state:on_buffer_entered(buf1_id)

		local buf3_id = add_buffer("test3")
		test_helpers.track_buffer(buf3_id)
		buffer_state:on_buffer_added(buf3_id) -- <test2><test3.lua><test1.lua>
		buffer_state:on_buffer_entered(buf3_id)

		assert.is_true(core.buffers[buf3_id] ~= nil)
		assert.is_true(vim.tbl_contains(core.buffer_order, buf3_id))
		assert.is_true(core.buffer_order[2] == buf3_id)
		assert.is_true(core.active_buf.index == 2)
	end)

	it("insert a second buffer into the list from index 1, behavior = after", function()
		core.config.default_insert_behavior = "after"
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		buffer_state:on_buffer_added(buf1_id) -- <test1>

		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		buffer_state:on_buffer_added(buf2_id) -- <test1><test2.lua>

		assert.is_true(core.buffers[buf2_id] ~= nil)
		assert.is_true(core.buffer_order[2] == buf2_id)
		assert.is_true(core.buffers[buf2_id].index == 2)
	end)

	it("inserts a third buffer into the list from index 1, behavior = after", function()
		core.config.default_insert_behavior = "after"
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)

		buffer_state:on_buffer_added(buf1_id) -- <test1>
		buffer_state:on_buffer_entered(buf1_id)

		buffer_state:on_buffer_added(buf2_id) -- <test1><test2.lua>
		buffer_state:on_buffer_entered(buf2_id)

		buffer_state:on_buffer_entered(buf1_id)

		local buf3_id = add_buffer("test3")
		test_helpers.track_buffer(buf3_id)
		buffer_state:on_buffer_added(buf3_id) -- <test1><test3.lua><test2.lua>
		buffer_state:on_buffer_entered(buf3_id)

		assert.is_true(core.buffers[buf3_id] ~= nil)
		assert.is_true(vim.tbl_contains(core.buffer_order, buf3_id))
		assert.is_true(core.buffer_order[2] == buf3_id)
		assert.is_true(core.active_buf.index == 2)
	end)

	it("inserts a third buffer into the list from index 2, behavior = after", function()
		core.config.default_insert_behavior = "after"
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)

		buffer_state:on_buffer_added(buf1_id) -- <test1>
		buffer_state:on_buffer_entered(buf1_id)

		buffer_state:on_buffer_added(buf2_id) -- <test1><test2.lua>
		buffer_state:on_buffer_entered(buf2_id)

		buffer_state:on_buffer_entered(buf2_id)

		local buf3_id = add_buffer("test3")
		test_helpers.track_buffer(buf3_id)
		buffer_state:on_buffer_added(buf3_id) -- <test1><test2.lua><test3.lua>
		buffer_state:on_buffer_entered(buf3_id)

		assert.is_true(core.buffers[buf3_id] ~= nil)
		assert.is_true(vim.tbl_contains(core.buffer_order, buf3_id))
		assert.is_true(core.buffer_order[3] == buf3_id)
		assert.is_true(core.active_buf.index == 3)
	end)
end)
