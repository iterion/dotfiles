{ pkgs, ... }: {
  imports = [ 
    ../base/mac-default.nix
    #./hardware-configuration.nix
  ];

  # Set Git commit hash for darwin-version.
  system.configurationRevision = null;#self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
