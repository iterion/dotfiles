{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../modules/lightsout
  ];

  # Enable networking
  networking.networkmanager.enable = true;

  networking.nameservers = [ "192.168.1.1" "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];

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
    # docker.rootless = {
    #   enable = true;
    #   setSocketVariable = true;
    # };
    libvirtd.enable = true;
    spiceUSBRedirection.enable = true;
  };

  # Configure console keymap
  console.keyMap = "dvorak";

  security.pam.loginLimits = [{
    domain = "*";
    type = "soft";
    item = "nofile";
    value = "16384";
  }];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.groups.plugdev = {};
  users.users.iterion = {
    isNormalUser = true;
    description = "Adam Sunderland";
    extraGroups = ["audio" "docker" "networkmanager" "wheel" "libvirtd" "plugdev"];
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
      options = "--delete-older-than 7d";
    };
    optimise = {
      automatic = true;
    };
    settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = [ "iterion" ];
    };
    package = pkgs.nixVersions.stable;
  };
  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;
    nvidia.acceptLicense = true;
    pulseaudio = true;
    permittedInsecurePackages = [
      "openssl-1.1.1w" # todo find and eliminate this bs
    ];
  };
  nixpkgs.overlays = [ 
    (final: prev: {
      pythonPackagesOverlays = (prev.pythonPackagesOverlays or [ ]) ++ [
        (python-final: python-prev: {
          phue = python-prev.buildPythonPackage rec {
            pname = "phue";
            version = "1.1";
            src = python-prev.fetchPypi {
              inherit pname version;
              sha256 = "sha256-YfrMmRourR1yffhRPQbOCJAzSJttygm+CT2yT3zbiHQ=";
            };
          };
        })
      ];
      python3 =
        let 
          self = prev.python3.override {
            inherit self;
            packageOverrides = prev.lib.composeManyExtensions final.pythonPackagesOverlays;
        }; in 
      self;

      python3Packages = final.python3.pkgs;
    })
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    systemPackages = with pkgs; [
      wget
      tailscale
      libsecret
      lshw
      usbutils
      inputs.alejandra.defaultPackage.${pkgs.system}
      # vagrant.override { withLibvirt = false; }
    ];
    pathsToLink = ["/share/zsh"];
    shells = with pkgs; [zsh];
  };

  fonts.packages = with pkgs; [
    font-awesome
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
  ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

  programs = {
    zsh.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  services = {

    udev = {
      enable = true;
      extraRules = ''

      '';
      packages = [
        (pkgs.writeTextFile {
          name = "usb-udev-rules";
          text = ''
            SUBSYSTEM=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", GROUP="plugdev", TAG+="uaccess"
            SUBSYSTEM=="usb", ATTRS{idVendor}=="2c99", GROUP="plugdev", TAG+="uaccess"
            '';
          destination = "/etc/udev/rules.d/70-usb.rules";
        })
      ];
    };
    resolved = {
      enable = true;
      dnssec = "true";
      domains = [ "~." ];
      fallbackDns = [ "192.168.1.1" "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
      dnsovertls = "true";
    };

    tailscale.enable = true;
    fstrim.enable = true;
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
