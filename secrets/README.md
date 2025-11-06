# Secrets managed with sops

This directory holds encrypted material that Home Manager decrypts through
`sops-nix`. To add your Pushover credentials:

1. Generate (or reuse) an age keypair:
   ```bash
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   ```
   Then start a new shell (or source your zsh profile) so the automatically
   exported `SOPS_AGE_KEY_FILE` and `SOPS_AGE_RECIPIENTS` variables are
   available.
2. Encrypt the secrets file:
   ```bash
   sops --encrypt --in-place secrets/codex.yaml
   ```
   Start from the following structure:
   ```yaml
   codex:
     pushover:
       token: "<app-token>"
       user: "<user-key>"
   ```
3. Re-run `home-manager switch` (or your flake activation command).

Because `home/devtools.nix` treats the file as optional, the configuration still
builds until you add the encrypted payload. Once encrypted, the CLI will export
`CODEX_NOTIFY_PUSHOVER_TOKEN` and `CODEX_NOTIFY_PUSHOVER_USER` automatically for
interactive shells, and the Codex notifier will forward pushes whenever your
session is locked. The decrypted values land at `~/.config/codex/pushover-token`
and `~/.config/codex/pushover-user`, which the notifier also reads directly, so
other processes (like Codex itself) do not have to inherit environment
variables.
