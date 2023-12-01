{ config, pkgs, ... }:

let
  mod = "Mod4";
  ws-web = "1: Web";
  ws-slack = "2: Slack";
  primaryUiFont = {
    names = [ "FiraCode Nerd Font" ];
    style = "Regular";
    size = 14.0;
  };

in 
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "iterion";
  home.homeDirectory = "/home/iterion";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    google-chrome
    alacritty
    _1password
    _1password-gui
    htop

    ripgrep
    xclip
    slack
    fzf
    rust-analyzer
    cargo
    rustc
    nil

    kubectl
    kubectx

    terraform
    terraform-ls
  ];

  fonts.fontconfig.enable = true;

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  home.sessionVariables = {};
  home.pointerCursor = {
    package = pkgs.vanilla-dmz;
    name = "Vanilla-DMZ";
    size = 64;
  };

  xdg.enable = true;
  xsession = {
    enable = true;
    windowManager.i3 = {
      enable = true;
      config = {
        keybindings = {
	  "${mod}+Return" = "exec ${pkgs.alacritty}/bin/alacritty";
	  "${mod}+d" = "exec ${pkgs.rofi}/bin/rofi -show run";
	  "${mod}+Tab" = "exec ${pkgs.rofi}/bin/rofi -show window";
	  "${mod}+Shift+apostrophe" = "kill";
	  
	  "${mod}+1" = "workspace ${ws-web}";
	  "${mod}+2" = "workspace ${ws-slack}";
	  "${mod}+3" = "workspace 3";
	  "${mod}+4" = "workspace 4";
	  "${mod}+5" = "workspace 5";
	  "${mod}+6" = "workspace 6";
	  "${mod}+7" = "workspace 7";
	  "${mod}+8" = "workspace 8";
	  "${mod}+9" = "workspace 9";
	  "${mod}+0" = "workspace 10";
	  "${mod}+Shift+1" = "move container to workspace ${ws-web}";
	  "${mod}+Shift+2" = "move container to workspace ${ws-slack}";
	  "${mod}+Shift+3" = "move container to workspace 3";
	  "${mod}+Shift+4" = "move container to workspace 4";
	  "${mod}+Shift+5" = "move container to workspace 5";
	  "${mod}+Shift+6" = "move container to workspace 6";
	  "${mod}+Shift+7" = "move container to workspace 7";
	  "${mod}+Shift+8" = "move container to workspace 8";
	  "${mod}+Shift+9" = "move container to workspace 9";
	  "${mod}+Shift+0" = "move container to workspace 10";

	  "${mod}+Shift+r" = "restart";
	};
        fonts = primaryUiFont;
        bars = [
          {
            fonts = primaryUiFont;
            position = "top";
            statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3status-rust/config-top.toml";
          }
        ];
      };
    };
    profileExtra = ''
      eval $(${pkgs.gnome3.gnome-keyring}/bin/gnome-keyring-daemon --daemonize --components=ssh,secrets)
      export SSH_AUTH_SOCK
    '';
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "brew"
        "kubectl" 
      ];
      theme = "robbyrussell";
    };
    shellAliases = {
      k = "kubectl";
    };
  };
  programs.git = {
    enable = true;
    userName = "Adam Sunderland";
    userEmail = "iterion@gmail.com";
    aliases = {
      co = "checkout";
      amend = "commit -a --amend";
      st = "status";
      b = "branch";
    };
    extraConfig = {
      color = {
        ui = "auto";
      };
      diff = {
        tool = "vimdiff";
        mnemonicprefix = true;
      };
      push = {
        default = "simple";
      };
    };
  };
  programs.i3status-rust = {
    enable = true;
    bars = {
      top = {
        icons = "awesome6";
        blocks = [
         {
           block = "time";
           interval = 60;
           format = "$icon $timestamp.datetime(f:'%a %Y-%m-%d %R %Z')";
         }
       ];
      };
    };
  };
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      nvim-treesitter.withAllGrammars
      vim-nix
      nvim-lspconfig
      cmp-nvim-lsp
      nvim-cmp
      luasnip
      fzf-vim
      fzf-lsp-nvim
      telescope-nvim
    ];
    extraLuaConfig = ./vim.lua;
  };
  programs.awscli = {
    enable = true;
    settings = ./aws-settings.nix;
  };

  services.gnome-keyring.enable = true;

  nixpkgs.config.allowUnfree = true;
}
