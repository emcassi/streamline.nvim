local it = require("plenary.busted").it
local describe = require("plenary.busted").describe
local test_helpers = require("tests.test_helpers")
local add_buffer = test_helpers.add_buffer

describe("Streamline add / remove buffers", function()
	local core = require("streamline.core.core")
	local buffer_state = require("streamline.core.buffer_state")

	before_each(function()
		test_helpers.reset_for_test(core)
	end)

	it("adds a buffer to the list", function()
		local buf_id = vim.api.nvim_create_buf(true, false)
		test_helpers.track_buffer(buf_id)

		assert.is_true(vim.api.nvim_buf_is_valid(buf_id))

		vim.api.nvim_buf_set_name(buf_id, "test")
		buffer_state:on_buffer_added(buf_id)

		assert.is_true(core:get_buffer_by_id(buf_id) ~= nil)
		assert.is_true(vim.tbl_contains(core:get_buffer_order(), buf_id))
	end)

	it("adds an identical buffer to the list", function()
		local buf_id = add_buffer("test")
		test_helpers.track_buffer(buf_id)
		assert.is_true(vim.api.nvim_buf_is_valid(buf_id))
		buffer_state:on_buffer_added(buf_id)
		local initial_length = core:get_num_buffers()

		local buf1_name = vim.api.nvim_buf_get_name(buf_id)
		local buf2_id = vim.api.nvim_create_buf(true, false)
		local success, _ = pcall(vim.api.nvim_buf_set_name, buf2_id, buf1_name)
		assert.is_false(success)
		assert.is_equal(initial_length, core:get_num_buffers())
	end)

	it("adds a scratch buffer to the list", function()
		local buf_id = vim.api.nvim_create_buf(false, true)
		test_helpers.track_buffer(buf_id)

		assert.is_true(vim.api.nvim_buf_is_valid(buf_id))

		vim.api.nvim_buf_set_name(buf_id, "test")
		buffer_state:on_buffer_added(buf_id)

		assert.is_true(core:get_buffer_by_id(buf_id) == nil)
		assert.is_false(vim.tbl_contains(core.buffer_order, buf_id))
	end)

	it("deletes the only buffer in the list", function()
		local buf_id = vim.api.nvim_create_buf(true, false)
		test_helpers.track_buffer(buf_id)
		assert.is_true(vim.api.nvim_buf_is_valid(buf_id))

		vim.api.nvim_buf_set_name(buf_id, "test")
		buffer_state:on_buffer_removed(buf_id)

		assert.is_true(core:get_buffer_by_id(buf_id) == nil)
		assert.is_false(vim.tbl_contains(core:get_buffer_order(), buf_id))
	end)

	it("deletes the active buffer in a list", function()
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		local buf3_id = add_buffer("test3")
		test_helpers.track_buffer(buf3_id)

		local buf2 = core:get_buffer_by_id(buf2_id)
		core:set_active_buffer(buf2)

		buffer_state:on_buffer_removed(core.active_buf)

		assert.is_true(core:get_buffer_by_id(buf2_id) == nil)
		assert.is_false(vim.tbl_contains(core:get_buffer_order(), buf2_id))
	end)

	it("deletes a buffer that was just inserted", function()
		local buf1_id = add_buffer("test1")
		test_helpers.track_buffer(buf1_id)
		buffer_state:on_buffer_added(buf1_id)

		local buf2_id = add_buffer("test2")
		test_helpers.track_buffer(buf2_id)
		buffer_state:on_buffer_added(buf2_id)
		buffer_state:on_buffer_entered(buf2_id)

		buffer_state:on_buffer_removed(buf2_id)

		assert.is_true(core:get_buffer_by_id(buf2_id) == nil)
		assert.is_false(vim.tbl_contains(core:get_buffer_order(), buf2_id))
	end)
end)
