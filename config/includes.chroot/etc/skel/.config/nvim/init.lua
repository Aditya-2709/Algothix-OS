-- Algothix OS (ALX) Lite — Minimal, fast Neovim configuration (FR-3.2)
-- Zero startup plugin overhead; optional LSP loads lazily only if installed.

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.smartindent = true
opt.ignorecase = true
opt.smartcase = true
opt.signcolumn = "yes"
opt.updatetime = 300
opt.splitright = true
opt.splitbelow = true
opt.termguicolors = true
opt.scrolloff = 4
opt.undofile = true
opt.swapfile = false

pcall(vim.cmd.colorscheme, "habamax")

-- Ergonomic keymaps
local map = vim.keymap.set
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
map("n", "<C-h>", "<C-w>h", { desc = "Focus left split" })
map("n", "<C-j>", "<C-w>j", { desc = "Focus lower split" })
map("n", "<C-k>", "<C-w>k", { desc = "Focus upper split" })
map("n", "<C-l>", "<C-w>l", { desc = "Focus right split" })

-- Optional lazy user overrides (e.g. LSP installed via alx-setup)
local local_cfg = vim.fn.stdpath("config") .. "/local.lua"
if vim.fn.filereadable(local_cfg) == 1 then
    dofile(local_cfg)
end
