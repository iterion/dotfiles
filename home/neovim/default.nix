{pkgs, ...}: {
  home.packages = with pkgs; [
    biome
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
      fzf-vim
      luasnip
      nvim-dap
      nvim-dap-virtual-text
      nvim-lspconfig
      nvim-treesitter.withAllGrammars
      plenary-nvim
      rustaceanvim
      telescope-nvim
      typescript-tools-nvim
    ];
    extraLuaConfig = builtins.readFile ./config.lua;
  };
}
