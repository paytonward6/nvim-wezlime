local M = {}

local get_block_bounds = function()
    local current_line_num = vim.api.nvim_win_get_cursor(0)[1]
    local num_lines = vim.api.nvim_buf_line_count(0)

    local above = current_line_num
    while vim.api.nvim_buf_get_lines(0, above - 1, above, false)[1] ~= "" do
        if above <= 0 then
            break
        end
        above = above - 1
    end

    local below = current_line_num
    while vim.api.nvim_buf_get_lines(0, below, below + 1, false)[1] ~= "" do
        below = below + 1
        if below >= num_lines then
            break
        end
    end

    return {start = above, last = below}
end

M.get_cur_block = function()
    local bounds = get_block_bounds()
    local text = vim.api.nvim_buf_get_lines(0, bounds.start, bounds.last, false)
    return text
end

return M
