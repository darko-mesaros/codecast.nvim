-- tests/minimal_init.lua
vim.cmd [[set runtimepath=$VIMRUNTIME]]
vim.cmd [[set packpath=/tmp/nvim/site]]
vim.cmd [[set hidden]]

local package_root = '/tmp/nvim/site/pack'
local install_path = package_root .. '/packer/start/packer.nvim'

local function load_plugins()
    require('packer').startup(function(use)
        use 'nvim-lua/plenary.nvim'
        use { '.',  path = vim.fn.getcwd() }
    end)
end

load_plugins()
require('plenary.busted')
