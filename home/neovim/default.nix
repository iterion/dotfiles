{pkgs, ...}: {
  home.packages = with pkgs; [
    nil
    rust-analyzer
    terraform-ls
    typescript
    yaml-language-server
    vscode-langservers-extracted
    zls
  ];
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      cmp-nvim-lsp
      fzf-lsp-nvim
      fzf-vim
      luasnip
      nvim-cmp
      nvim-dap
      nvim-dap-virtual-text
      nvim-lspconfig
      nvim-treesitter.withAllGrammars
      plenary-nvim
      rust-tools-nvim
      telescope-nvim
      vim-nix
      typescript-tools-nvim
    ];
    extraLuaConfig = builtins.readFile ./config.lua;
  };
}
