-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--
-- Kickstart binds that LazyVim already has (not repeated):
--   <Esc> clear search, [d ]d diagnostics, <C-h/j/k/l> windows (tmux-navigator owns these),
--   gd/gr/K, <leader>ca, yank highlight, <Esc><Esc> leave terminal.
-- Kickstart <leader>e was diagnostic float; here <leader>e is neo-tree. Use <leader>cd.
-- Kickstart <leader>f was format; here <leader>f is find. Format is <leader>cf (off: vim.g.autoformat).

-- neuronvim: <leader>sf was fff find-files. Map it to snacks, keep LazyVim <leader><space> / <leader>ff.
vim.keymap.set("n", "<leader>sf", function()
  Snacks.picker.files()
end, { desc = "Find Files" })

-- Kickstart rename was <leader>rn; LazyVim uses <leader>cr.
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
