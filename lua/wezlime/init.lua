local wezterm = require("wezlime.wezterm")

local M = {}


-- Commands have signature of function(args, context) where `args` are _all_
-- of the arguments passed to `:Wezlime`, including the command name, and context
-- is the parameter passes to `M.wezlime` via `vim.api.nvim_create_user_command`
local commands = {
    send = { command = wezterm.send },
    send_line = { command = wezterm.send_line },
    reload_pane = { command = wezterm.reload_pane, output = true },
    get_pane = { command = wezterm.get_pane, output = true },
    set_pane = { command = wezterm.set_pane, output = true },
}

M.wezlime = function(context)
    local args = {}
    for substring in string.gmatch(context.args, "%S+") do
       table.insert(args, substring)
    end

    local cmd = commands[args[1]]
    if cmd then
        local output = cmd.command(args, context)
        if cmd.output then
            vim.print(output)
        end
    else
        error("Wezlime command " .. args[1] .. " does not exist")
    end
end

M.setup = function(opts)
    vim.api.nvim_create_user_command("Wezlime", M.wezlime, {
        nargs = "+",
        range = true,
        complete = function(line)
            return vim.tbl_filter(function(val)
                return vim.startswith(val, line)
            end, vim.tbl_keys(commands))
        end,
    })

    wezterm:setup(opts)
end

return M
