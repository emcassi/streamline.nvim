local it = require("plenary.busted").it
local describe = require("plenary.busted").describe
local test_helpers = require("tests.test_helpers")
local add_buffer = test_helpers.add_buffer

describe("Streamline swap buffer", function()
	local core = require("streamline.core")

	before_each(function()
		test_helpers.reset_for_test(core)
	end)

	it("swap buffers at index 1 and 2 in a list of 2", function()
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)
		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		core:swap_buffer_with(1, 2)

		assert.is_equal(core.active_buf.id, buf2_id)
		assert.is_equal(core.buffer_order[1], buf2_id)
		assert.is_equal(core.buffer_order[2], buf1_id)
	end)

	it("swap buffers at index 1 and 3 in a list of 3", function()
		core.config.default_insert_behavior = "end"

		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)
		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)
		local buf3_id = add_buffer("test3")
		test_helpers.track_buffer(buf3_id)
		core:on_buffer_added(buf3_id)
		core:on_buffer_entered(buf3_id)

		core:swap_buffer_with(1, 3)

		assert.is_equal(core.active_buf.id, buf3_id)
		assert.is_equal(core.buffer_order[1], buf3_id)
		assert.is_equal(core.buffer_order[2], buf2_id)
		assert.is_equal(core.buffer_order[3], buf1_id)
	end)
end)
