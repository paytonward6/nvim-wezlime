# nvim-wezlime

Slime implementation for Wezterm

## Installation

### Packer

```lua
require("packer").startup(function()
  use({
    "paytonward6/nvim-wezlime",
    config = function()
      require("wezlime").setup({
        -- default mappings
        relative_direction = "right"
      })
    end,
  })
end)
```

## Configuration

### Commands

* `Wezlime send`: sends the current paragraph (or visual selection) to target pane
* `Wezlime send_line`: sends the current line (or visual selection) to target pane
* `Wezlime reload_pane`: recomputes target pane's ID and caches it
* `Wezlime set_pane <PANE ID: int>`: manually set the target pane to `<PANE ID: int>`
* `Wezlime get_pane`: get the ID of the target pane

### Example keymaps

```lua
local opts = { noremap = true, silent = true }

-- Must use `:` instead of `<Cmd>` or visual mode will not work properly
vim.keymap.set({"n", "v"}, "<leader>ee", ":Wezlime send<CR>", opts)
vim.keymap.set({"n", "v"}, "<leader>e.", ":Wezlime send_line<CR>", opts)
```

