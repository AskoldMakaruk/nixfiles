# ai-sandbox

Isolated NixOS microvm for running AI agents against codebases.
- QEMU, 4 vCPU, 4 GB RAM
- Tools: kilocode, dotnet SDK 10, nodejs/npm, git, ripgrep
- Network: whitelist-only outbound (DNS + 80/443/22), SSH-in from host LAN only
- Persistence: /home/agent (20 GB), workspace/context via virtiofs bind mounts

---

## Setup (once)

```bash
nix flake update microvm --flake .
batat-roll
sudo microvm -u ai-sandbox
```

Add to `~/.ssh/config`:
```
Host ai-sandbox
  HostName 10.100.0.2
  User agent
  StrictHostKeyChecking no
```

---

## Start / Stop

```bash
start-ai-sandbox ~/projects/my-app
start-ai-sandbox ~/projects/my-app ~/notes/context   # with context dir (ro)
stop-ai-sandbox
```

Script blocks — VM runs in foreground, Ctrl-C stops and unmounts.

---

## Connect & use

```bash
ssh ai-sandbox
cd /workspace
kilocode                       # interactive
kilocode "fix the bug in X"    # one-shot
dotnet build
npm install && npm run dev
```

---

## After config changes

```bash
batat-roll                   # rebuild host + new VM config
sudo microvm -u ai-sandbox   # apply to running VM
```

---

## Persistence

| What | Where | Persists? |
|------|-------|-----------|
| Agent home, caches, claude config | `/home/agent` (20 GB volume) | yes |
| Repo | `/workspace` (bind from host) | lives on host |
| Context | `/context` (bind from host, ro) | lives on host |
| OS / packages | Nix store (read-only) | rebuilt on `microvm -u` |

VM state: `/var/lib/microvms/ai-sandbox/`

---

## Troubleshoot

```bash
systemctl status microvm@ai-sandbox
journalctl -u microvm@ai-sandbox -f
ip addr show br-ai      # bridge up?
ip link show ai-tap0    # tap in bridge?
```
