# nvim-wezlime

Slime implementation for Wezterm

## Installation

### Packer

```lua
require("packer").startup(function()
  use({
    "paytonward6/nvim-wezlime",
    config = function()
      require("wezlime").setup()
    end,
  })
end)
```

## Usage

> Currently only supports a right pane as a target

### Commands

* `Wezlime send`: sends the current paragraph to target pane (or visual selection)
* `Wezlime reload_pane`: recomputes target pane's ID and caches it
* `Wezlime get_pane`: get the ID of the target pane

### Example keymaps

```lua
local opts = { noremap = true, silent = true }

-- Must use `:` instead of `<Cmd>` or visual mode will not work properly
vim.keymap.set({"n", "v"}, "<leader>ee", ":Wezlime send<CR>", opts)
```

