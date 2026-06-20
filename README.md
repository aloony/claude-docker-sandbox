# claude-docker-sandbox

Run [Claude Code](https://claude.com/claude-code) inside a disposable Docker
container instead of directly on your machine. The agent gets a full dev
toolchain and your repo mounted at `/claude`, but it **can't touch the rest of
your host** — no `sudo`, no access to paths you didn't mount, a clean filesystem
every run.

Why bother:

- **Blast radius.** The agent runs as a non-root user in a container. A bad
  command hits the container, not your home directory.
- **Reproducible.** The toolchain is pinned in the `Dockerfile`; every run
  starts from the same image.
- **Multiple identities.** *Profiles* let you keep separate logins, settings,
  and credentials (e.g. `work` vs `personal`) that never bleed into each other.

---

## Requirements

- Docker with the Compose plugin (`docker compose`, v2).
- A Linux host. `network_mode: host` and the PulseAudio mount assume Linux; on
  macOS/Windows see [Audio / `/voice`](#audio--voice) to drop those bits.

## Install

```sh
curl -LsSf https://raw.githubusercontent.com/aloony/claude-docker-sandbox/master/install.sh | sh
```

This clones the repo into `~/.local/share/claude-sandbox` and symlinks the
`claude-sandbox` launcher into `~/.local/bin`. Re-run it any time to update
(`git pull` under the hood). Override locations with `CLAUDE_SANDBOX_HOME` /
`XDG_BIN_HOME`. Piping a script to `sh` is convenient but you're trusting it —
read it first if you like: `curl -LsSf <url> -o install.sh && less install.sh`.

Prefer to do it by hand? Clone anywhere and symlink the launcher yourself:

```sh
git clone https://github.com/aloony/claude-docker-sandbox.git
ln -s "$PWD/claude-docker-sandbox/claude-sandbox" ~/.local/bin/claude-sandbox
```

## Quick start

```sh
# Run the example profile against the repo in the current directory:
claude-sandbox example .

# …or against any other repo:
claude-sandbox example ~/code/my-project
```

First run builds the image (a few minutes) and walks you through Claude Code
login. Login and history persist across runs (see [State vs. profile](#state-vs-profile)),
so subsequent runs start instantly and stay logged in.

---

## How it works

Three pieces: the **image** (`Dockerfile`), the **runtime wiring**
(`docker-compose.yml`), and the **launcher** (`claude-sandbox`).

### The launcher

`claude-sandbox <profile> [path]` resolves a few environment variables and calls
`docker compose run`:

| Variable            | Value                              | Purpose                                  |
| ------------------- | ---------------------------------- | ---------------------------------------- |
| `CLAUDE_PROFILE_DIR`| `./profiles/<profile>`             | Versioned config mounted into the agent. |
| `CLAUDE_STATE_DIR`  | `$HOME/.claude-<profile>`          | Live, machine-local state + credentials. |
| `UID` / `GID`       | your user/group                    | Files the agent creates are owned by you.|

The target repo is mounted with `-v <repo>:/claude`, and `--rm` throws the
container away when you exit.

### State vs. profile

This split is the important idea:

- **State dir** — `$HOME/.claude-<profile>` → `/home/node/.claude`
  Holds credentials (`.credentials.json`), login/onboarding state
  (`.claude.json`), history, sessions, and caches. **Machine-local, secret,
  never committed.** One per profile, so your work and personal logins are fully
  separate.

- **Profile dir** — `./profiles/<profile>` → individual files under
  `/home/node/.claude`
  Holds versioned config: `settings.json`, `CLAUDE.md`, and `skills/`.
  These are bind-mounted **read-write and individually**, so edits Claude makes
  in-session flow straight back into this repo — commit and pull them on another
  machine and your setup follows you.

`CLAUDE_CONFIG_DIR=/home/node/.claude` is set so that login state lands in the
mounted state dir (and thus persists) rather than the container's ephemeral
overlay.

### Profiles

A profile is just a directory under `profiles/`:

```
profiles/example/
├── CLAUDE.md          # global user instructions, read every session
├── settings.json      # model, theme, permissions
└── skills/            # custom slash-command skills (.gitkeep keeps it tracked)
```

Copy `example` to make your own:

```sh
cp -r profiles/example profiles/work
./claude-sandbox work ~/code/job-repo
```

The included `example` profile ships a conservative `permissions.allow` list as a
starting point — tighten or loosen it to taste.

---

## Audio / `/voice`

The image installs ALSA/PulseAudio bits and the compose file mounts the host's
PipeWire/PulseAudio socket so Claude Code's `/voice` can record the mic. This is
**optional and Linux-specific** — the mount path `/run/user/${UID}/pulse` assumes
a standard systemd session. To drop it:

- In `docker-compose.yml`, remove the `PULSE_SERVER` env line and the
  `/run/user/${UID}/pulse:...` volume.
- In the `Dockerfile`, you can delete the `alsa-utils … libsox-fmt-all` apt
  block and the `/etc/asound.conf` write.

---

## Security notes

- **Never commit a state dir or any `*.local.json`.** Credentials and API tokens
  belong in `$HOME/.claude-<profile>`, which lives outside this repo. The
  `.gitignore` blocks `settings.local.json`, `.credentials.json`, and
  `.claude-*/` as a backstop — but treat profiles as *public* and keep secrets
  out of `settings.json`, `CLAUDE.md`, and skills.
- The container uses `network_mode: host`, so it shares your host network. Tighten
  this (e.g. a bridge network) if you want network isolation too.
- The agent runs as your `UID`/`GID` so created files are yours — that also means
  anything mounted read-write is genuinely writable. Only mount what you intend
  the agent to change.

## Customizing the image

Edit the `Dockerfile` and re-run — Compose rebuilds on change. The base is
`node:22-slim` (Debian 12) with git, ripgrep, Python + `uv`, the GitHub CLI,
build tooling, and assorted CLI utilities. The Claude Code npm version is pinned;
bump it there.

## License

[MIT](./LICENSE)
