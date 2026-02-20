{pkgs, ...}: let
  treesitterGrammars = grammars: with grammars; [
    bash
    hcl
    javascript
    json
    lua
    markdown
    markdown_inline
    nix
    query
    regex
    rust
    toml
    tsx
    typescript
    vim
    vimdoc
    yaml
    zig
  ];
in {
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
    withNodeJs = false;
    withPython3 = false;
    withRuby = false;
    plugins = with pkgs.vimPlugins; [
      fzf-vim
      nvim-dap
      nvim-dap-virtual-text
      nvim-lspconfig
      (nvim-treesitter.withPlugins treesitterGrammars)
      plenary-nvim
      rustaceanvim
      telescope-nvim
      typescript-tools-nvim
    ];
    initLua = builtins.readFile ./config.lua;
  };
}
