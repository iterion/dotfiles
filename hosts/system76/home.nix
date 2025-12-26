{ ... }: {
  iterion.desktop.enable = true;
  iterion.work.enable = true;
  wayland.windowManager.hyprland = {
    settings = {
      monitor = [
        "eDP-1,1920x1080@144,0x0,1"
        "HDMI-A-3,3840x2160,1920x0,1.5"
      ];
      device = [
        {
          name = "clearly-superior-technologies.-cst-laser-trackball";
          sensitivity = -0.5;
        }
      ];
    };
  };
}
