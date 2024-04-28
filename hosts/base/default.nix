{
  pkgs,
  inputs,
  ...
}: {
  # Enable networking
  networking.networkmanager.enable = true;

  networking.nameservers = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];

  # Set your time zone.
  time.timeZone = "America/Detroit";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  virtualisation = {
    docker.enable = true;
    docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # Configure console keymap
  console.keyMap = "dvorak";

  # Enable ALSA
  sound.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.iterion = {
    isNormalUser = true;
    description = "Adam Sunderland";
    extraGroups = ["audio" "networkmanager" "wheel"];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINWdZ6Ae9HwLtPBGCQVjbsHbF0lCADWTAEXW+nZzY6mh iterion"
    ];
  };

  boot = {
    # Bootloader.
    loader = {
      efi.canTouchEfiVariables = true;
    };
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 1w";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
    };
    package = pkgs.nixFlakes;
  };
  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;
    pulseaudio = true;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    systemPackages = with pkgs; [
      wget
      tailscale
      libsecret
      lshw
      inputs.alejandra.defaultPackage.${pkgs.system}
    ];
    pathsToLink = ["/share/zsh"];
    shells = with pkgs; [zsh];
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
    resolved = {
      enable = true;
      dnssec = "true";
      domains = [ "~." ];
      fallbackDns = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
      dnsovertls = "true";
    };

    tailscale.enable = true;
    fstrim.enable = true;
    gvfs.enable = true;
    tumbler.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
  };
}