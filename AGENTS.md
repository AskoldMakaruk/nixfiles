# AGENTS.md — Askold's dotfiles

This is a **NixOS dotfiles / flake repository**. There is no CI, no test framework, no pre-commit hooks. The repo is purely declarative Nix configuration.

## Architecture

`flake.nix` at root defines 4 NixOS configurations (hostnames: `lenovo`, `pc`, `timba-1`, `timba-2`). Module layout:

- `parts/` — reusable NixOS/home-manager modules gated behind `batat.<feature>` enable-flags (e.g. `batat.kde.enable`, `batat.nvim.enable`)
- `hosts/<hostname>/` — per-machine configs importing from `parts/`. `configuration.nix` for system, `home.nix` for user-level
- `nixos/modules/` — shared NixOS modules (tailscale, fluent-bit, nextcloud)
- `services/` — self-hosted app configs (forgejo, garage, nextcloud, grocy, affine, etc.) typically imported by hosts
- `pkgs/` — custom Nix packages (e.g. `pkgs/kilocode/default.nix`)
- `envs/` — per-language `nix-shell` environments (`rust/stable/`, `rust/unstable/`, `dotnet/`, `go/`, `node/`, `bot/`)

## Essential commands

| Action | Command |
|---|---|
| Rebuild system | `sudo nixos-rebuild switch --flake .#<hostname>` |
| Update flake lock | `nix flake update` |
| Enter dev shell | `nix-shell envs/rust/stable/shell.nix` (or `nr` from ZSH: `nr envs/rust/unstable` runs one command in that shell) |
| Trim old Nix gens | `./trim.sh` (keeps last 30 by default) |
| GC old generations | `batat-gc` (alias) |
| List generations | `batat-list` (alias) |
| Open dotfiles in nvim | `batat-edit` (alias) |

## Secrets

Managed with **agenix**. Encrypted `.age` files live in a separate private repo at `~/secrets/` (not in this repo). The flake input `mysecrets` points there.

## .kilocode config

The `.kilocode/` directory configures the KiloCode AI agent itself (CLI settings, MCP, custom modes `Architect` and `Ask`). Do not delete or restructure it.

## Formatters

- Nix: `nixfmt-rfc-style` (via LSP `nil` with `nixfmt` command — see `parts/nvim/config/nvim/coc-settings.json`)
- Lua: `stylua` — 2-space indent, 120 col width (`parts/nvim/config/nvim/stylua.toml`)
- Shell: `shfmt`
- C#: `csharpier` (`dotnet-csharpier`)

## AI-sandbox system user

The `agent` system user (`/home/agent`) runs AI agents in isolation directly on the host. See `hosts/ai-sandbox/README.md` for usage. The host machine config includes `start-ai-sandbox` / `stop-ai-sandbox` scripts.

## Key quirks

- Dotfiles are managed via Nix, **not** by symlinks to the repo root. The flake builds `/etc/nixos/` and home-manager manages `~/` configs.
- JetBrains IDEs use `config/ideavimrc` (extensive IdeaVim config with Russian layout support via `ол` → `<Esc>`). See `config/ideavim.README.md`.
- Neovim config is LazyVim-based at `parts/nvim/config/nvim/`.
- No Makefile, no Dockerfile in this repo (Docker containers are built via Nix in `parts/deployment/`).
