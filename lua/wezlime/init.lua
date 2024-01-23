local wezterm = require("wezlime.wezterm")

local M = {}

M.wezlime = function(context)
    local args = {}
    for substring in string.gmatch(context.args, "%S+") do
       table.insert(args, substring)
    end

    if args[1] == "send" then
        wezterm:send(context)
    elseif args[1] == "send_line" then
        wezterm:send_line()
    elseif args[1] == "reload_pane" then
        vim.print(wezterm:reload_pane())
    elseif args[1] == "get_pane" then
        vim.print(wezterm:get_pane())
    elseif args[1] == "set_pane" then
        vim.print(wezterm:set_pane(args[2]))
    end
end

M.setup = function(opts)
    local commands = {"send", "send_line", "reload_pane", "get_pane", "set_pane"}
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
