local it = require("plenary.busted").it
local describe = require("plenary.busted").describe
local test_helpers = require("tests.test_helpers")
local add_buffer = test_helpers.add_buffer

describe("Streamline reinsert buffers", function()
	local core = require("streamline.core.core")
	local buffer_state = require("streamline.core.buffer_state")
	local reordering = require("streamline.core.reordering")

	before_each(function()
		test_helpers.reset_for_test(core)
	end)

	it("reinsert a buffer at index 1 before index 1 in a list of 2", function()
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		buffer_state:on_buffer_added(buf1_id)
		buffer_state:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		buffer_state:on_buffer_added(buf2_id)
		buffer_state:on_buffer_entered(buf2_id)

		reordering:reinsert_buffer_before_index(1, 1)

		assert.is_equal(core:get_active_buf().id, buf2_id)
		assert.is_equal(core:get_buffer_order()[1], buf1_id)
		assert.is_equal(core:get_buffer_order()[2], buf2_id)
	end)

	it("reinsert a buffer at index 1 before index 2 in a list of 2", function()
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		buffer_state:on_buffer_added(buf1_id)
		buffer_state:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		buffer_state:on_buffer_added(buf2_id)
		buffer_state:on_buffer_entered(buf2_id)

		reordering:reinsert_buffer_before_index(1, 2)

		assert.is_equal(core:get_active_buf().id, buf2_id)
		assert.is_equal(core:get_buffer_order()[1], buf1_id)
		assert.is_equal(core:get_buffer_order()[2], buf2_id)
	end)

	it("reinsert a buffer at index 2 before index 1 in a list of 2", function()
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		buffer_state:on_buffer_added(buf1_id)
		buffer_state:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		buffer_state:on_buffer_added(buf2_id)
		buffer_state:on_buffer_entered(buf2_id)

		reordering:reinsert_buffer_before_index(2, 1)

		assert.is_equal(core:get_active_buf().id, buf2_id)
		assert.is_equal(core:get_buffer_order()[1], buf2_id)
		assert.is_equal(core:get_buffer_order()[2], buf1_id)
	end)

	it("reinsert a buffer at index 3 before index 2 in a list of 3", function()
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		buffer_state:on_buffer_added(buf1_id)
		buffer_state:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		buffer_state:on_buffer_added(buf2_id)
		buffer_state:on_buffer_entered(buf2_id)

		local buf3_id = add_buffer("test3")
		test_helpers.track_buffer(buf3_id)
		buffer_state:on_buffer_added(buf3_id)
		buffer_state:on_buffer_entered(buf3_id)

		reordering:reinsert_buffer_before_index(3, 2)

		assert.is_equal(core:get_active_buf().id, buf3_id)
		assert.is_equal(core:get_buffer_order()[1], buf1_id)
		assert.is_equal(core:get_buffer_order()[2], buf3_id)
		assert.is_equal(core:get_buffer_order()[3], buf2_id)
	end)

	it("reinsert a buffer at index 2 after index 2 in a list of 2", function()
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		buffer_state:on_buffer_added(buf1_id)
		buffer_state:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		buffer_state:on_buffer_added(buf2_id)
		buffer_state:on_buffer_entered(buf2_id)

		reordering:reinsert_buffer_after_index(2, 2)

		assert.is_equal(core:get_active_buf().id, buf2_id)
		assert.is_equal(core:get_buffer_order()[1], buf1_id)
		assert.is_equal(core:get_buffer_order()[2], buf2_id)
	end)

	it("reinsert a buffer at index 2 after index 1 in a list of 2", function()
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		buffer_state:on_buffer_added(buf1_id)
		buffer_state:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		buffer_state:on_buffer_added(buf2_id)
		buffer_state:on_buffer_entered(buf2_id)

		reordering:reinsert_buffer_after_index(2, 1)

		assert.is_equal(core:get_active_buf().id, buf2_id)
		assert.is_equal(core:get_buffer_order()[1], buf1_id)
		assert.is_equal(core:get_buffer_order()[2], buf2_id)
	end)

	it("reinsert a buffer at index 1 after index 2 in a list of 2", function()
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		buffer_state:on_buffer_added(buf1_id)
		buffer_state:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		buffer_state:on_buffer_added(buf2_id)
		buffer_state:on_buffer_entered(buf2_id)

		reordering:reinsert_buffer_after_index(1, 2)

		assert.is_equal(core:get_active_buf().id, buf2_id)
		assert.is_equal(core:get_buffer_order()[1], buf2_id)
		assert.is_equal(core:get_buffer_order()[2], buf1_id)
	end)

	it("reinsert a buffer at index 1 after index 2 in a list of 3", function()
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		buffer_state:on_buffer_added(buf1_id)
		buffer_state:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		buffer_state:on_buffer_added(buf2_id)
		buffer_state:on_buffer_entered(buf2_id)

		local buf3_id = add_buffer("test3")
		test_helpers.track_buffer(buf3_id)
		buffer_state:on_buffer_added(buf3_id)
		buffer_state:on_buffer_entered(buf3_id)

		reordering:reinsert_buffer_after_index(1, 2)

		assert.is_equal(core:get_active_buf().id, buf3_id)
		assert.is_equal(core:get_buffer_order()[1], buf2_id)
		assert.is_equal(core:get_buffer_order()[2], buf3_id)
		assert.is_equal(core:get_buffer_order()[3], buf1_id)
	end)

	it("reinsert a buffer at index 1 before index 2 in a list of 2 by id", function()
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		buffer_state:on_buffer_added(buf1_id)
		buffer_state:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		buffer_state:on_buffer_added(buf2_id)
		buffer_state:on_buffer_entered(buf2_id)

		reordering:reinsert_buffer_before_id(buf1_id, buf2_id)

		assert.is_equal(core:get_active_buf().id, buf2_id)
		assert.is_equal(core:get_buffer_order()[1], buf1_id)
		assert.is_equal(core:get_buffer_order()[2], buf2_id)
	end)

	it("reinsert a buffer at index 2 before index 1 in a list of 2 by id", function()
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		buffer_state:on_buffer_added(buf1_id)
		buffer_state:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		buffer_state:on_buffer_added(buf2_id)
		buffer_state:on_buffer_entered(buf2_id)

		reordering:reinsert_buffer_before_id(buf2_id, buf1_id)

		assert.is_equal(core:get_active_buf().id, buf2_id)
		assert.is_equal(core:get_buffer_order()[1], buf2_id)
		assert.is_equal(core:get_buffer_order()[2], buf1_id)
	end)

	it("reinsert a buffer at index 3 before index 2 in a list of 3 by id", function()
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		buffer_state:on_buffer_added(buf1_id)
		buffer_state:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		buffer_state:on_buffer_added(buf2_id)
		buffer_state:on_buffer_entered(buf2_id)

		local buf3_id = add_buffer("test3")
		test_helpers.track_buffer(buf3_id)
		buffer_state:on_buffer_added(buf3_id)
		buffer_state:on_buffer_entered(buf3_id)

		reordering:reinsert_buffer_before_id(buf3_id, buf2_id)

		assert.is_equal(core:get_active_buf().id, buf3_id)
		assert.is_equal(core:get_buffer_order()[1], buf1_id)
		assert.is_equal(core:get_buffer_order()[2], buf3_id)
		assert.is_equal(core:get_buffer_order()[3], buf2_id)
	end)

	it("reinsert a buffer at index 2 after index 1 in a list of 2 by id", function()
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		buffer_state:on_buffer_added(buf1_id)
		buffer_state:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		buffer_state:on_buffer_added(buf2_id)
		buffer_state:on_buffer_entered(buf2_id)

		reordering:reinsert_buffer_after_id(buf2_id, buf1_id)

		assert.is_equal(core:get_active_buf().id, buf2_id)
		assert.is_equal(core:get_buffer_order()[1], buf1_id)
		assert.is_equal(core:get_buffer_order()[2], buf2_id)
	end)

	it("reinsert a buffer at index 1 after index 2 in a list of 2 by id", function()
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		buffer_state:on_buffer_added(buf1_id)
		buffer_state:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		buffer_state:on_buffer_added(buf2_id)
		buffer_state:on_buffer_entered(buf2_id)

		reordering:reinsert_buffer_after_id(buf1_id, buf2_id)

		assert.is_equal(core:get_active_buf().id, buf2_id)
		assert.is_equal(core:get_buffer_order()[1], buf2_id)
		assert.is_equal(core:get_buffer_order()[2], buf1_id)
	end)

	it("reinsert a buffer at index 1 after index 2 in a list of 3 by id", function()
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		buffer_state:on_buffer_added(buf1_id)
		buffer_state:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		buffer_state:on_buffer_added(buf2_id)
		buffer_state:on_buffer_entered(buf2_id)

		local buf3_id = add_buffer("test3")
		test_helpers.track_buffer(buf3_id)
		buffer_state:on_buffer_added(buf3_id)
		buffer_state:on_buffer_entered(buf3_id)

		reordering:reinsert_buffer_after_id(buf1_id, buf2_id)

		assert.is_equal(core:get_active_buf().id, buf3_id)
		assert.is_equal(core:get_buffer_order()[1], buf2_id)
		assert.is_equal(core:get_buffer_order()[2], buf3_id)
		assert.is_equal(core:get_buffer_order()[3], buf1_id)
	end)

	it("reinsert a buffer at index 1 before index 2 directly after swapping them", function()
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		buffer_state:on_buffer_added(buf1_id)
		buffer_state:on_buffer_entered(buf1_id)

		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		buffer_state:on_buffer_added(buf2_id)
		buffer_state:on_buffer_entered(buf2_id)

		reordering:swap_buffer_with(1, 2)
		reordering:reinsert_buffer_before_index(2, 1)

		assert.is_equal(core:get_active_buf().id, buf2_id)
		assert.is_equal(core:get_buffer_order()[1], buf1_id)
		assert.is_equal(core:get_buffer_order()[2], buf2_id)
	end)
end)
