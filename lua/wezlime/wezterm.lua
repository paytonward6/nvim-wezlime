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
    else
        return self.current_pane_id
    end
end

function M:set_pane(id)
    local pane_id = tonumber(id)
    if pane_id then
        self.current_pane_id = pane_id
    else
        error("Wezterm pane ID must be a number")
    end
end

M.send_text = function(pane_id, text)
    local command = {"wezterm", "cli", "send-text", "--pane-id", pane_id}
    local out = vim.fn.system(command, text)
    return out
end

function M:send(lines)
    local text = vim.fn.join(lines, "\n") .. "\n"
    local pane_id = self:target_pane({reload = false})
    self.send_text(pane_id, text)
end

function M:reload_pane()
    self:target_pane({reload = true})
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
