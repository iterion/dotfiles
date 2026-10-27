# dotfiles

To rebuild on NixOS, from the root of this dir run:
```
sudo nixos-rebuild switch --flake .
```

This of course assumes that flake.nix outputs a relevant NixOS config based on the current hostname.

## Rex on Linux

Home Manager installs the official Rex snapshot package and runs a personal
`rex` systemd user service on every Linux host. User lingering keeps sessions
alive after logout. Rex uses built-in Tailscale and joins the tailnet as
`rex-<hostname>`; only the device's Tailscale owner can connect by default.

Rex's Linux packages currently require a tester package token. Configure package
authentication on the machine evaluating the flake and on each Linux builder
before locking or rebuilding. Keep the token outside this repository and the
Nix store; do not put it in the flake URL.

- On NixOS, add the following entry to `/etc/nix/netrc` with `sudoedit`, then
  restrict it with `sudo chmod 600 /etc/nix/netrc`:

  ```text
  machine pkgs.superlogical.com
    login rex
    password <REX_PACKAGE_TOKEN>
  ```

  The base configuration sets `nix.settings.netrc-file` to that path. Use root
  to lock the input with this root-readable credential file. For the first
  rebuild, pass the path explicitly too:

  ```bash
  sudo nix flake update rex --option netrc-file /etc/nix/netrc
  sudo nixos-rebuild switch --flake . --option netrc-file /etc/nix/netrc
  ```

- With Determinate Nix, put the same entry in `/etc/determinate/rex.netrc` and
  add that path to
  `authentication.additionalNetrcSources` in `/etc/determinate/config.json`,
  following the [Rex installation guide](https://www.superlogical.com/rex/docs/linux/installation#nix-and-nixos).
  Preserve any existing configuration. Determinate Nix manages
  `/nix/var/determinate/netrc` itself.

  The configured source file must exist. After changing the configuration or
  the source netrc file, restart the Determinate daemon. On macOS:

  ```bash
  sudo launchctl kickstart -k system/systems.determinate.nix-daemon
  ```

  To use the credential file directly for one command, pass its path explicitly:

  ```bash
  nix flake update rex --option netrc-file /etc/determinate/rex.netrc
  ```

  If a restart still leaves Rex out of the generated netrc, check
  `/var/log/determinate-nix-daemon.log`. Failed FlakeHub authentication can
  prevent custom netrc sources from being merged, as reported in
  [Determinate issue #173](https://github.com/DeterminateSystems/determinate/issues/173).
  The explicit `--option netrc-file` command above bypasses that merge. To
  restore FlakeHub authentication, run `determinate-nixd auth login` and complete
  the login with your FlakeHub account.

After Determinate Nix authentication is configured, lock the Rex input with
`nix flake update rex`.
On each Linux host, after rebuilding, run `rex server status` or
`journalctl --user -u rex` to find its Tailscale sign-in link and open it to enroll
the device. The tailnet needs MagicDNS and HTTPS certificates enabled. In Rex for
Mac, use **Add Remote Host…** with `https://rex-<hostname>.<tailnet>.ts.net`.

See the [Rex Home Manager module](https://www.superlogical.com/rex/docs/linux/installation#the-home-manager-module)
and [remote access guide](https://www.superlogical.com/rex/docs/linux/remote-access#built-in-tailscale)
for service and Tailscale details.
