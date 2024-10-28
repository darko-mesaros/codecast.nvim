-- tests/minimal_init.lua
local plenary_path = vim.fn.stdpath("data") .. "/site/pack/vendor/start/plenary.nvim"

-- Set up paths
vim.cmd [[set runtimepath=$VIMRUNTIME]]
vim.cmd [[set packpath=/tmp/nvim/site]]

-- Add our plugin and plenary to runtimepath
local plugin_path = vim.fn.getcwd()
vim.opt.runtimepath:append(plugin_path)
vim.opt.runtimepath:append(plenary_path)

-- Load plenary
require('plenary.busted')
