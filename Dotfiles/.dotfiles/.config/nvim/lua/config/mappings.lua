-- NeoVim
vim.g.mapleader = " "
vim.keymap.set({ 'n', 'v' }, 'd', '"_d', { noremap = true })
vim.keymap.set({ 'n', 'v' }, 'x', '"_x', { noremap = true })
vim.keymap.set({ 'n', 'v' }, 'c', '"_c', { noremap = true })
vim.keymap.set('v', 'p', '"_dP', { noremap = true })

-- NeoTree
vim.keymap.set('n', '<leader>e', ':Neotree float focus<CR>')
vim.keymap.set('n', '<leader>o', ':Neotree left focus<CR>')

-- Lsp
vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)

-- Bufferline
vim.keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<CR>", { desc = "Следующая вкладка" })
vim.keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Предыдущая вкладка" })
vim.keymap.set("n", "<leader>x", "<cmd>BufferLinePickClose<CR>", { desc = "Закрыть текущую вкладку" })
vim.keymap.set("n", "<leader>cls", "<cmd>BufferLineCloseOthers<CR>", { desc = "Закрыть остальные вкладки" })
vim.keymap.set("n", "<leader>t", "<cmd>BufferLinePick<CR>", { desc = "Выбрать вкладку по букве (Picker)" })
