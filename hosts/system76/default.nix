{ config, pkgs, ... }: {
  imports =
    [ 
      ../base
      ../desktop
      ./hardware-configuration.nix
    ];

  networking.hostName = "system76-nixos";

  boot.initrd.luks.devices."luks-bcdc740f-7023-4bb5-982f-081db97f671f".device = "/dev/disk/by-uuid/bcdc740f-7023-4bb5-982f-081db97f671f";

  hardware.system76.enableAll = true;
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.systemPackages = [];

  # use systemd boot as we don't need grub
  boot.loader.systemd-boot.enable = true;
  
  # Enable graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = [
      pkgs.intel-media-driver
      pkgs.nvidia-vaapi-driver
      pkgs.vaapiVdpau
    ];
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  environment.variables = {
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    NVD_BACKEND = "direct";
    EGL_PLATFORM = "wayland";
  };

  virtualisation = {
    docker = {
      enableNvidia = true;
    };
  };

  # just testing k3s for now:
  networking.firewall = {
    allowedTCPPorts = [
      6443 # needed for pod comms with k8s API
    ];
    allowedUDPPorts = [ ];
  };
  services.k3s = {
    enable = true;
    role = "server";
  };

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = true;

    # open source driver, it sucks, don't use.
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "535.171.04";
      sha256_64bit = "sha256-6PFkO0vJXYrNZaRHB4SpfazkZC8UkjZGYSDbKqlCQ3o=";
      settingsSha256 = "sha256-/+op7FyDk6JH+Oau3dGtawCUtoDdOnfxEXBgYVfufTA=";
      persistencedSha256 = "sha256-P90qWA1yObhQQl3sKTWw+uUq7S9ZZcCzKnx/jHbfclo=";

      #version = "550.40.07";
      #sha256_64bit = "sha256-KYk2xye37v7ZW7h+uNJM/u8fNf7KyGTZjiaU03dJpK0=";
      #sha256_aarch64 = "sha256-AV7KgRXYaQGBFl7zuRcfnTGr8rS5n13nGUIe3mJTXb4=";
      #openSha256 = "sha256-mRUTEWVsbjq+psVe+kAT6MjyZuLkG2yRDxCMvDJRL1I=";
      #settingsSha256 = "sha256-c30AQa4g4a1EHmaEu1yc05oqY01y+IusbBuq+P6rMCs=";
      #persistencedSha256 = "sha256-11tLSY8uUIl4X/roNnxf5yS2PQvHvoNjnd2CB67e870=";
    };

    prime = {
      #offload = {
      #  enable = true;
      #  enableOffloadCmd = true;
      #};
      reverseSync.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
