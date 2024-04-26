# dotfiles

To rebuild on NixOS, from the root of this dir run:
```
sudo nixos-rebuild switch --flake .
```

This of course assumes that flake.nix outputs a relevant NixOS config based on the current hostname.
