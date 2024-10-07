-- load old "init.vim" (renamed as "vimrc.vim")
local vimrc = vim.fn.stdpath("config") .. "/vimrc.vim"
vim.cmd.source(vimrc)

-- packer
require('packer').startup(function(use)
    use 'wbthomason/packer.nvim'
end)
