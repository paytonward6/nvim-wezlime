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
        if not wezterm:get_pane() then
            wezterm:reload_pane()
        end

        wezterm:send(text)
        if vim.v.shell_error == 1 then
            -- 1 means no pane has such ID reload and try again...
            wezterm:reload_pane()
            wezterm:send(text)
        elseif vim.v.shell_error > 0 then
            error("Error writing text to Wezterm pane " .. wezterm.current_pane_id)
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
        vim.print(wezterm:get_pane())
    elseif args[1] == "set_pane" then
        wezterm:set_pane(args[2])
    end
end

M.setup = function(opts)
    local commands = {"send", "reload_pane", "get_pane", "set_pane"}
    vim.api.nvim_create_user_command("Wezlime", M.wezlime, {
        nargs = "+",
        range = true,
        complete = function(line)
            return vim.tbl_filter(function(val) return vim.startswith(val, line) end, commands)
        end,
    })

    wezterm:setup(opts)
end

return M
