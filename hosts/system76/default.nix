{ config, lib, pkgs, ... }: {
  imports =
    [ 
      ../base
      ../desktop
      ./hardware-configuration.nix
    ];

  networking = {
    hostName = "system76-nixos";
  };

  boot.kernelPackages = pkgs.linuxPackages;
  boot.initrd.luks.devices."luks-bcdc740f-7023-4bb5-982f-081db97f671f".device = "/dev/disk/by-uuid/bcdc740f-7023-4bb5-982f-081db97f671f";
  # Temporary bootstrap mode: stay on the Intel iGPU and keep the dGPU out of
  # the graphics stack until the laptop is stable again.
  boot.initrd.kernelModules = [ "i915" ];
  boot.blacklistedKernelModules = [
    "nouveau"
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
  ];

  hardware.system76.enableAll = true;
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # use systemd boot as we don't need grub
  boot.loader.systemd-boot.enable = true;
  
  # Enable graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = [
      pkgs.intel-media-driver
    ];
  };

  services.xserver.videoDrivers = [ "modesetting" ];
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

  environment.sessionVariables = {
    AQ_DRM_DEVICES = "/dev/dri/by-path/pci-0000:00:02.0-card";
    LIBVA_DRIVER_NAME = "iHD";
    NIXOS_OZONE_WL = "1";
  };
  environment.systemPackages = [
    pkgs.fleetctl
    pkgs.osquery
  ];
  services.osquery.enable = true;

  # just testing k3s for now:
  networking.firewall = {
    allowedTCPPorts = [
      8585 # running machine-api locally
      6443 # needed for pod comms with k8s API
    ];
    allowedUDPPorts = [
      5353 # mDNS allow for machine-api
    ];
  };
  services.k3s = {
    enable = false;
    role = "server";
  };

  hardware.nvidia-container-toolkit.enable = false;

  specialisation.dgpu.configuration = {
    system.nixos.tags = [ "dgpu" ];

    boot.initrd.kernelModules = lib.mkForce [ "nvidia" ];
    boot.kernelParams = [ "nvidia-drm.fbdev=1" ];
    boot.extraModprobeConfig = ''
      options nvidia_uvm uvm_disable_hmm=1
    '';
    boot.blacklistedKernelModules = lib.mkForce [ "i915" ];

    hardware.graphics.extraPackages = [ pkgs.nvidia-vaapi-driver ];
    services.xserver.videoDrivers = lib.mkForce [ "nvidia" ];

    environment.sessionVariables = {
      AQ_DRM_DEVICES = lib.mkForce "/dev/dri/by-path/pci-0000:01:00.0-card";
      LIBVA_DRIVER_NAME = lib.mkForce "nvidia";
      GBM_BACKEND = "nvidia-drm";
      NVD_BACKEND = "direct";
      EGL_PLATFORM = "wayland";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
    };

    hardware.nvidia-container-toolkit.enable = lib.mkForce true;
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = true;
      open = true;
      package = config.boot.kernelPackages.nvidiaPackages.beta;

      prime = {
        reverseSync.enable = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
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
