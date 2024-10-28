# CodeCast.nvim

> NOTE: This plugin is still in it's early stages. Kind of a way for me to learn Lua and the Neovim ecosystem

A Neovim plugin for creating code demonstrations with typewriter effects.

## Installation

With Lazy:
```lua
{
    'darko-mesaros/codecast.nvim',
    dependencies = {
        'nvim-lua/plenary.nvim',
    },
    config = function()
        require('codecast').setup()
    end
}
```

## Configuration

CodeCast.nvim can be configured with custom settings and keybindings. Here's an example with all available options and their default values:

```lua
require('codecast').setup({
    -- Directory where your code snippets are stored
    snippets_dir = vim.fn.stdpath('config') .. '/codecast/snippets',
    
    -- Speed of typewriter effect (milliseconds between characters)
    typewriter_speed = 50,
    
    -- Default insertion mode ('typewriter' or 'instant')
    default_insert_mode = 'typewriter',
    
    -- Custom keybindings
    keybindings = {
        -- Global mappings
        show_snippets = '<leader>cc',  -- Open snippet selector
        
        -- Snippet selector mappings
        instant_insert = '<CR>',       -- Insert snippet instantly
        typewriter_insert = '<leader><CR>', -- Insert with typewriter effect
        close_selector = '<Esc>',      -- Close snippet selector
        
        -- Typewriter control mappings
        stop_typing = '<C-c>'           -- Stop typewriter effect (can be single key or table)
        pause_typing = '<C-p>',        -- Pause typewriter effect
        resume_typing = '<C-g>'        -- Resume typewriter effect
    }
})
```

### Customizing Keybindings

You can customize any or all keybindings. Here's an example with some custom keys:

```lua
require('codecast').setup({
    keybindings = {
        show_snippets = '<leader>s',     -- Change the snippet selector trigger
        instant_insert = '<C-i>',        -- Change instant insert key
        typewriter_insert = '<C-t>',     -- Change typewriter insert key
        stop_typing = '<C-x>',           -- Single key to stop typing
        -- or multiple keys:
        stop_typing = {'<C-x>', '<C-q>'} -- Multiple keys to stop typing
    }
})
```

Note: You only need to specify the keybindings you want to change. Any unspecified keybindings will use their default values.

## Usage

1. Store your code snippets in the configured snippets directory (default: `~/.config/nvim/codecast/snippets/`)
2. Press `<leader>cc` (or your configured `show_snippets` key) to open the snippet selector
3. Select a snippet and:
   - Press `<CR>` (or your configured `instant_insert` key) to insert it instantly
   - Press `<leader><CR>` (or your configured `typewriter_insert` key) to insert with typewriter effect

### Typewriter Controls

When using the typewriter effect:
- Press `<C-c>` (or your configured `stop_typing` key) to stop the effect
- Press `<C-p>` (or your configured `pause_typing` key) to pause
- Press `<C-g>` (or your configured `resume_typing` key) to resume

## Contributing

Contributions are welcome! Please feel free to submit pull requests.

