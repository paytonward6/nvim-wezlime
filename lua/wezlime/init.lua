local wezterm = require("wezlime.wezterm")
local block = require("wezlime.block")

local M = {}

local wezlime_send = function(context)
    local text = nil
    if context.range == 0 then
        text = block.get_cur_block()
    elseif context.range > 0 then
        text = vim.api.nvim_buf_get_lines(0, context.line1 - 1, context.line2, false)
    end

    if text ~= nil then
        wezterm:send(text)
        if vim.v.shell_error == 2 then
            -- 2 means no pane has such ID
            -- reload and try again...
            wezterm:reload_pane()
            wezterm:send(text)
        elseif vim.v.shell_error > 0 then
            error("Error writing text to Wezterm pane " .. M.current_pane_id)
        end
    else
        vim.print("No text to send to pane")
    end
end

M.wezlime = function(context)
    local args = {}
    for substring in string.gmatch(context.args, "%S+") do
       table.insert(args, substring)
    end

    if args[1] == "send" then
        wezlime_send(context)
    elseif args[1] == "reload_pane" then
        wezterm:reload_pane()
    elseif args[1] == "get_pane" then
        wezterm:get_pane()
    end
end

M.setup = function(opts)
    vim.api.nvim_create_user_command("Wezlime", M.wezlime, {nargs = 1, range = true})

    wezterm:setup(opts)
end

return M
