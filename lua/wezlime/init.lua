local M = {}

M.current_pane_id = nil

local wezterm_list_clients = function()
    local output = vim.fn.system("wezterm cli list-clients --format json")
    local json = vim.json.decode(output)
    return json
end


local wezterm_pane_right = function()
    local output = vim.fn.system("wezterm cli get-pane-direction right")
    output = vim.trim(output)
    if output == "" then
        error("No right Wezterm pane detected")
    end
    return output
end


local target_pane = function(opts)
    if M.current_pane_id == nil or opts.reload then
        M.current_pane_id = wezterm_pane_right()
    else
        return M.current_pane_id
    end
end


local wezterm_send_text = function(pane_id, text)
    local command = {"wezterm", "cli", "send-text", "--pane-id", pane_id}
    vim.fn.system(command, text)
end

local current_pane_id = function()
    local client_json = wezterm_list_clients()
    assert(table.getn(client_json) == 1, "More than one wezterm client detected")

    local client = client_json[1]
    return client.focused_pane_id
end

local wezterm_list = function()
    local output = vim.fn.system("wezterm cli list --format json")
    local json = vim.json.decode(output)
    return json
end

local current_pane_info = function()
    local current_pane_id = current_pane_id()

    for _, v in pairs(wezterm_list()) do
        if v.pane_id == current_pane_id then
            return {
                pane_id = current_pane_id,
                tab_id = v.tab_id,
                window_id = v.window_id
            }
        end
    end
end

local slime_pane = function()
    local current_pane = current_pane_info()

    for _, v in pairs(wezterm_list()) do
        if v.pane_id == current_pane.pane_id then
            goto continue
        elseif v.tab_id == current_pane.tab_id then
            return {
                pane_id = v.pane_id,
                tab_id = v.tab_id,
                window_id = v.window_id,
            }
        end
        ::continue::
    end
end

local _get_block_bounds = function()
    local current_line_num = vim.api.nvim_win_get_cursor(0)[1]
    local num_lines = vim.api.nvim_buf_line_count(0)

    local above = current_line_num
    while vim.api.nvim_buf_get_lines(0, above - 1, above, false)[1] ~= "" do
        above = above - 1
        if above <= 0 then
            above = above + 1
            goto continue
        end
    end
    above = above + 1
    ::continue::

    local below = current_line_num
    while vim.api.nvim_buf_get_lines(0, below, below + 1, false)[1] ~= "" do
        below = below + 1
        if below >= num_lines then
            return  {
                start = above,
                last = below,
            }
        end
    end

    return {start = above, last = below}
end

M.get_cur_block = function()
    local bounds = _get_block_bounds()
    local text = vim.api.nvim_buf_get_lines(0, bounds.start - 1, bounds.last, false)

    return text
end

local send = function(lines)
    local text = vim.fn.join(lines, "\n")
    wezterm_send_text(target_pane({reload = false}), text)
    wezterm_send_text(target_pane({reload = false}), "\n")
end

local wezlime_reload_pane = function()
    target_pane({reload = true})
end

local wezlime_send = function(context)
    local text = nil
    if context.range == 0 then
        text = M.get_cur_block()
    elseif context.range > 0 then
        text = vim.api.nvim_buf_get_lines(0, context.line1 - 1, context.line2, false)
    end

    if text ~= nil then
        send(text)
        if vim.v.shell_error == 2 then
            -- 2 means no pane has such ID
            -- reload and try again...
            wezlime_reload_pane()
            send(text)
        else
            error("Error writing text to Wezterm pane " .. M.current_pane_id)
        end
    else
        vim.print("No text to send to pane")
    end
end


local get_pane = function()
    vim.print(M.current_pane_id)
end


M.wezlime = function(context)
    local args = {}
    for substring in string.gmatch(context.args, "%S+") do
       table.insert(args, substring)
    end

    if args[1] == "send" then
        wezlime_send(context)
    elseif args[1] == "reload_pane" then
        wezlime_reload_pane()
    elseif args[1] == "get_pane" then
        get_pane()
    end
end

M.setup = function()
    vim.api.nvim_create_user_command("Wezlime", M.wezlime, {nargs = 1, range = true})
end


return M
