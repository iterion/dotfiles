{
  pkgs,
  inputs,
  ...
}: {
  imports = [
  ];

  # Set your time zone.
  time.timeZone = "America/Detroit";

  # Configure console keymap
  #console.keyMap = "dvorak";

  nix = {
    gc = {
      automatic = true;
      interval = {
        Day = 5;
      };
      options = "--delete-older-than 1w";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
      trusted-users = [ "iterion" ];
    };
    package = pkgs.nixFlakes;
  };

  homebrew = {
    enable = true;
    #font-fira-code			
    #font-inconsolata-nerd-font	
    casks = [
      "iterm2"
      "1password-cli"
      "github"
      "slack"
      "warp"
      "zoom"
      "docker"
      "gpg-suite"
      "mysql-shell"
      "spotify"
      "xquartz"
    ];
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;
  };
  users.users.iterion = {
    description = "Adam Sunderland";
    shell = pkgs.nushell;
    home = "/Users/iterion";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINWdZ6Ae9HwLtPBGCQVjbsHbF0lCADWTAEXW+nZzY6mh iterion"
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    systemPackages = with pkgs; [
      wget
      tailscale
      inputs.alejandra.defaultPackage.${pkgs.system}
    ];
    pathsToLink = ["/share/zsh"];
    shells = with pkgs; [zsh nushell];
  };

  fonts.packages = with pkgs; [
    font-awesome
    nerdfonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
  ];

  programs = {
    zsh.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  services = {
    tailscale.enable = true;
  };
}
