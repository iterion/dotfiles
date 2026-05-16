{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.framework-16-amd-ai-300-series-nvidia
    ../base
    ../desktop
    ./hardware-configuration.nix
  ];

  networking.hostName = "framework-16";

  boot = {
    loader.systemd-boot.enable = true;
    initrd.luks.devices."luks-b2aeb4e9-6fec-49f7-a40b-166fafdbf771".device =
      "/dev/disk/by-uuid/b2aeb4e9-6fec-49f7-a40b-166fafdbf771";
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    nvidia.prime = {
      amdgpuBusId = "PCI:194:0:0";
      nvidiaBusId = "PCI:193:0:0";
    };
  };

  environment.sessionVariables = {
    # Prefer the AMD iGPU for the internal panel, but keep the NVIDIA dGPU
    # available to Hyprland for external outputs wired to it. AQ_DRM_DEVICES is
    # colon-delimited, so by-path PCI names with colons are parsed incorrectly.
    AQ_DRM_DEVICES = "/dev/dri/framework-amd-card:/dev/dri/framework-nvidia-card";
  };

  services = {
    hardware.bolt.enable = true;

    udev.extraRules = ''
      SUBSYSTEM=="drm", KERNEL=="card[0-9]*", KERNELS=="0000:c2:00.0", SYMLINK+="dri/framework-amd-card"
      SUBSYSTEM=="drm", KERNEL=="card[0-9]*", KERNELS=="0000:c1:00.0", SYMLINK+="dri/framework-nvidia-card"
    '';
  };

  environment.systemPackages = with pkgs; [
    lm_sensors
    pciutils
  ];

  system.stateVersion = "25.11";
}
