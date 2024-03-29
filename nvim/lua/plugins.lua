vim.cmd [[packadd packer.nvim]]

-- automatically run ":PackerCompile" whenever plugins.lua is updated
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerCompile
  augroup end
]])

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  -- You add plugins here
  use 'lambdalisue/suda.vim'    -- :w for root files
  use 'frabjous/knap'           -- LaTeX live update

end)
