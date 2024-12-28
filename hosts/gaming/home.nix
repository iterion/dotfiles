{ ... }: {
  iterion.desktop.enable = true;
  wayland.windowManager.hyprland = {
    settings = {
      monitor = [
        "HDMI-A-1,3840x2160,0x0,1"
      ];
    };
  };
}
