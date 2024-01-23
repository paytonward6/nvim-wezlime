local block = require("wezlime.block")

local M = {}

M.current_pane_id = nil

local validate_direction = function(direction)
    local directions = {"up", "down", "left", "right", "next", "prev"}

    for _, d in ipairs(directions) do
        if string.lower(direction) == d then
            return direction
        end
    end
    error("Invalid Wezterm direction: " .. direction)
end

function M:setup(opts)
    if not self.config then
        self.config = {}
    end

    local direction = opts.relative_direction or "right"
    self.config.relative_direction = validate_direction(direction)

end

function M:get_pane()
    return self.current_pane_id
end

local wezterm_list_clients = function()
    local output = vim.fn.system("wezterm cli list-clients --format json")
    local json = vim.json.decode(output)
    return json
end

function M:wezterm_pane()
    local output = vim.fn.system({"wezterm", "cli", "get-pane-direction", self.config.relative_direction})
    output = vim.trim(output)
    if output == "" then
        error("No " .. self.config.relative_direction .. " Wezterm pane detected")
    end
    return output
end

function M:target_pane(opts)
    if self.current_pane_id == nil or opts.reload then
        self.current_pane_id = self:wezterm_pane()
    end
    return self.current_pane_id
end

function M:set_pane(id)
    local pane_id = tonumber(id)
    if pane_id then
        self.current_pane_id = pane_id
    else
        error("Wezterm pane ID must be a number")
    end
    return self.current_pane_id
end

M.send_text = function(pane_id, text)
    local command = {"wezterm", "cli", "send-text", "--pane-id", pane_id}
    local out = vim.fn.system(command, text)
    return out
end

function M:send_lines(lines)
    local text = vim.fn.join(lines, "\n") .. "\n"
    local pane_id = self:target_pane({reload = false})
    self.send_text(pane_id, text)
end

function M:send_line()
    local text = vim.api.nvim_get_current_line() .. "\n"
    local pane_id = self:target_pane({reload = false})

    self.send_text(pane_id, text)
    if vim.v.shell_error == 1 then
        -- 1 means no pane has such ID reload and try again...
        self:reload_pane()
        self.send_text(pane_id, text)
    elseif vim.v.shell_error > 0 then
        error("Error writing text to Wezterm pane " .. self.current_pane_id)
    end
end

function M:send(context)
    local text = nil
    if context.range == 0 then
        text = block.get_cur_block()
    elseif context.range > 0 then
        text = vim.api.nvim_buf_get_lines(0, context.line1 - 1, context.line2, false)
    end

    if text ~= nil then
        if not self:get_pane() then
            self:reload_pane()
        end

        self:send_lines(text)
        if vim.v.shell_error == 1 then
            -- 1 means no pane has such ID reload and try again...
            self:reload_pane()
            self:send_lines(text)
        elseif vim.v.shell_error > 0 then
            error("Error writing text to Wezterm pane " .. self.current_pane_id)
        end
    else
        vim.print("No text to send to pane")
    end
end

function M:reload_pane()
    return self:target_pane({reload = true})
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
    local pane_id = current_pane_id()

    for _, v in pairs(wezterm_list()) do
        if v.pane_id == pane_id then
            return {
                pane_id = pane_id,
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

return M
