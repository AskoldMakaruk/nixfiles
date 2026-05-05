# ai-sandbox

Isolated system user (`agent`) with its own home directory at `/home/agent`.
Runs directly on the host — no VM overhead — but as a separate user for isolation.

- Tools: kilocode, dotnet SDK 10, nodejs/npm, git, ripgrep, chromium
- No network namespace — uses host networking (firewall handles isolation if needed)

---

## Setup (once)

```bash
batat-roll
```

---

## Start / Stop

```bash
start-ai-sandbox ~/projects/my-app   # mounts repo, drops into agent shell
start-ai-sandbox                      # just drop into agent shell
stop-ai-sandbox                       # unmounts workspace
```

`start-ai-sandbox` binds the repo to `/home/agent/workspace` and spawns a login
shell as the `agent` user. Type `exit` or Ctrl-D to return. Workspace is
unmounted automatically on exit.

---

## Use

From within the agent shell:

```bash
cd /workspace
kilocode                        # interactive
kilocode "fix the bug in X"     # one-shot
dotnet build
npm install && npm run dev
```

Or SSH in from another machine (if SSH is enabled for the agent):
```bash
ssh agent@<host-ip>
```

---

## Persistence

| What | Where | Persists? |
|------|-------|-----------|
| Agent home, caches, `.kilocode` state | `/home/agent` | yes |
| Repo | `/home/agent/workspace` (bind mount) | lives on host path |
| OS / packages | Nix store | rebuilt on `batat-roll` |

---

## After config changes

```bash
batat-roll
```

---

## Troubleshoot

```bash
sudo -u agent -i                              # drop into agent shell directly
ls -la /home/agent/                           # check agent home
mountpoint -q /home/agent/workspace && echo mounted
```
