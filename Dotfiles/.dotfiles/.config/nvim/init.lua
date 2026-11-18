-- BASIC
require("config.lazy")
require("config.mappings")
require("config.nvim")

-- PLUGINS
vim.opt.termguicolors = true
require('neo-tree').setup({close_if_last_window = true})
require("plugins.dracula")
require("plugins.treesitter")
require("plugins.lsp")
require("plugins.bufferline")
require('lualine').setup()
