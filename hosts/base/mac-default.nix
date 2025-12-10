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

  # Disable for determinate nix install
  nix = {
    enable = false;
    # gc = {
    #   automatic = true;
    #   interval = {
    #     Day = 5;
    #   };
    #   options = "--delete-older-than 1w";
    # };
    # optimise = {
    #   automatic = true;
    # };
    # settings = {
    #   experimental-features = ["nix-command" "flakes"];
    #   trusted-users = [ "iterion" ];
    # };
    # package = pkgs.nixVersions.stable;
  };

  environment.etc."nix/nix.conf".text = ''
    extra-substituters = https://devenv.cachix.org
    extra-trusted-public-keys = devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=
    trusted-users = root iterion
  '';

  homebrew = {
    enable = true;
    casks = [
      "1password-cli"
      "github"
      "slack"
      "zoom"
      "docker"
      "gpg-suite"
      "spotify"
      "xquartz"
    ];
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };
  system.primaryUser = "iterion";

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
      fleetctl
      alejandra
      codex
    ];
    pathsToLink = ["/share/zsh"];
    shells = with pkgs; [
      zsh
      nushell
    ];
  };

  fonts.packages = with pkgs; [
    font-awesome
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
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
