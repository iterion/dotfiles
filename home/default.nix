{
  pkgs,
  lib,
  inputs,
  ...
}: let 
  homeDir = if pkgs.stdenv.isLinux then "/home/iterion" else "/Users/iterion";
in {
  imports = [
    inputs.anyrun.homeManagerModules.anyrun
    inputs.nix-index-database.hmModules.nix-index

    ./devtools.nix
    ./fpv.nix
    ./neovim

    ./desktop
  ];

  home = {
    username = "iterion";
    homeDirectory = lib.mkForce homeDir;

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
    # cli tools
    vault
    htop
    dig.dnsutils
    fzf
    bat
    jq
    yq-go
    lsof
    ripgrep
    killall

    # usb debugging
    hidviz

    # for convenience put this in every shell
    kubectl
    kubectx

    inputs.ghostty.packages.x86_64-linux.default
  ];
  programs = {
    btop = {
      enable = true;
      settings = {
        color_theme = "gruvbox_dark";
        theme_background = false; # make btop transparent
      };
    };

    zellij = {
      enable = true;
      enableZshIntegration = false;
      settings = {
        pane_frames = false;
        default_layout = "compact";
        copy_command = if pkgs.stdenv.isLinux then "wl-copy" else "pbcopy";
        copy_on_select = true;
      };
    };

    nix-index.enable = true;
    nix-index-database.comma.enable = true;

    # fans & temps
    #coolercontrol.enable = true;
  };

  fonts.fontconfig.enable = true;

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {};

  home.sessionVariables = {};
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
