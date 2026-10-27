{
  inputs,
  osConfig,
  ...
}: {
  imports = [
    inputs.rex.homeManagerModules.default
  ];

  programs.rex.enable = true;
  # Rex installs its xterm-rex fallback in the managed SSH configuration.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
  };

  services.rex = {
    enable = true;
    tailscale = {
      enable = true;
      # Each personal server joins the tailnet as its own device.
      hostname = "rex-${osConfig.networking.hostName}";
    };
  };
}
