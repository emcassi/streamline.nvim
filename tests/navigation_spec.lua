local it = require("plenary.busted").it
local describe = require("plenary.busted").describe
local test_helpers = require("tests.test_helpers")
local add_buffer = test_helpers.add_buffer

describe("Streamline navigation", function()
	local core = require("streamline.core")

	before_each(function()
		test_helpers.reset_for_test(core)
	end)

	it("go to the buffer before the current in the list of 2", function()
		local buf1_id = add_buffer("test1.lua")
		test_helpers.track_buffer(buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		test_helpers.track_buffer(buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		core:navigate_backward()

		assert.is_equal(core.active_buf.id, buf1_id)
	end)

	it("go to the buffer before the current in the list of 3", function()
		local buf1_id = add_buffer("test1.lua")
		test_helpers.track_buffer(buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		test_helpers.track_buffer(buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		local buf3_id = add_buffer("test3.lua")
		test_helpers.track_buffer(buf3_id)
		core:on_buffer_added(buf3_id)
		core:on_buffer_entered(buf3_id)

		core:navigate_backward()

		assert.is_equal(core.active_buf.id, buf2_id)
	end)

	it("navigation wraps around the list going backwards", function()
		local buf1_id = add_buffer("test1.lua")
		test_helpers.track_buffer(buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		test_helpers.track_buffer(buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		local buf3_id = add_buffer("test3.lua")
		test_helpers.track_buffer(buf3_id)
		core:on_buffer_added(buf3_id)
		core:on_buffer_entered(buf3_id)

		core:navigate_backward()
		core:navigate_backward()
		core:navigate_backward()

		assert.is_equal(core.active_buf.id, buf3_id)
	end)

	it("go to the buffer after the current in the list of 2", function()
		local buf1_id = add_buffer("test1.lua")
		test_helpers.track_buffer(buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		test_helpers.track_buffer(buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		core:on_buffer_entered(buf1_id)

		core:navigate_forward()

		assert.is_equal(core.active_buf.id, buf2_id)
	end)

	it("go to the buffer after the current in the list of 3", function()
		local buf1_id = add_buffer("test1.lua")
		test_helpers.track_buffer(buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		test_helpers.track_buffer(buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		local buf3_id = add_buffer("test3.lua")
		test_helpers.track_buffer(buf3_id)
		core:on_buffer_added(buf3_id)
		core:on_buffer_entered(buf3_id)

		core:on_buffer_entered(buf2_id)

		core:navigate_forward()

		assert.is_equal(core.active_buf.id, buf3_id)
	end)

	it("navigation wraps around the list going forwards", function()
		local buf1_id = add_buffer("test1.lua")
		test_helpers.track_buffer(buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2.lua")
		test_helpers.track_buffer(buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		local buf3_id = add_buffer("test3.lua")
		test_helpers.track_buffer(buf3_id)
		core:on_buffer_added(buf3_id)
		core:on_buffer_entered(buf3_id)

		core:navigate_forward()
		core:navigate_forward()
		core:navigate_forward()

		assert.is_equal(core.active_buf.id, buf3_id)
	end)

	it("go to the previous buffer in a list of 1", function()
		local buf1_id = add_buffer("test1.lua")
		test_helpers.track_buffer(buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)

		core:navigate_to_previous() -- no previous buffer

		assert.is_equal(core.active_buf.id, buf1_id)
	end)

	it("go to the previous buffer in a list of 2", function()
		local buf1_id = add_buffer("test1.lua")
		test_helpers.track_buffer(buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)
		local buf2_id = add_buffer("test2.lua")
		test_helpers.track_buffer(buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)

		core:navigate_to_previous() -- previous buffer should be buf1

		assert.is_equal(core.active_buf.id, buf1_id)
	end)

	it("go to the previous buffer in a list of 3", function()
		local buf1_id = add_buffer("test1.lua")
		test_helpers.track_buffer(buf1_id)
		core:on_buffer_added(buf1_id)
		core:on_buffer_entered(buf1_id)
		local buf2_id = add_buffer("test2.lua")
		test_helpers.track_buffer(buf2_id)
		core:on_buffer_added(buf2_id)
		core:on_buffer_entered(buf2_id)
		local buf3_id = add_buffer("test3.lua")
		test_helpers.track_buffer(buf3_id)
		core:on_buffer_added(buf3_id)
		core:on_buffer_entered(buf3_id)

		core:on_buffer_entered(buf1_id)

		core:navigate_to_previous() -- previous buffer should be buf1

		assert.is_equal(core.active_buf.id, buf3_id)
	end)
end)
