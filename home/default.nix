{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.anyrun.homeManagerModules.anyrun
    inputs.hyprlock.homeManagerModules.hyprlock
    inputs.hypridle.homeManagerModules.hypridle
    inputs.hyprpaper.homeManagerModules.hyprpaper

    ./alacritty.nix
    ./devtools.nix
    ./waybar.nix
    ./neovim
    ./hyprland.nix
    ./anyrun.nix
  ];

  home = {
    username = "iterion";
    homeDirectory = "/home/iterion";

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "23.05"; # Please read the comment before changing.
  };

  home.packages = with pkgs; [
    # desktop apps
    _1password
    _1password-gui
    discord
    google-chrome
    spotify
    slack
    zoom-us
    obsidian


    # cli tools
    vault
    htop
    dig.dnsutils
    fzf
    bat
    jq
    lsof
    ripgrep
    killall
    nix-index

    # for convenience put this in every shell
    kubectl
    kubectx
  ];
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "gruvbox_dark";
      theme_background = false; # make btop transparent
    };
  };

  fonts.fontconfig.enable = true;

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {};

  home.sessionVariables = {};
  xdg.enable = true;
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}