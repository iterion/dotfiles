{
  pkgs,
  inputs,
  ...
}: {
  # Enable networking
  networking.networkmanager.enable = true;

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
    # packages = with pkgs; [];
  };

  boot = {
    # Bootloader.
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    plymouth = {
      enable = true;
      theme = "breeze";
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
      polkit_gnome
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
    dconf.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    seahorse.enable = true;
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = ["iterion"];
    };
    # file picker
    xfconf.enable = true;
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
  };

  services = {
    # Enable the OpenSSH daemon.
    openssh.enable = true;
    tailscale.enable = true;
    fstrim.enable = true;
    gvfs.enable = true;
    tumbler.enable = true;
    dbus = {
      enable = true;
      packages = [pkgs.gnome.seahorse];
    };
    gnome.gnome-keyring.enable = true;
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.hyprland}/bin/Hyprland";
        };
      };
    };

    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "dvorak";
      };
    };
  };
}
