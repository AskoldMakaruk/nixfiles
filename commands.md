
## Nix flake cheatsheet

Update lock file:

```bash
nix flake update
```

Switch to new system built from this flake.
`.#profilename` to select profile
```bash
sudo nixos-rebuild switch --flake .#<pc or lenovo>
```

