#!/bin/sh
# install.sh — one-command installer for claude-docker-sandbox.
#
#   curl -LsSf https://raw.githubusercontent.com/aloony/claude-docker-sandbox/main/install.sh | sh
#
# It clones (or, if already present, updates) the repo into a data dir, then
# symlinks the `claude-sandbox` launcher onto your PATH. Re-running it updates an
# existing install. Nothing is installed system-wide and no sudo is needed.
#
# Override locations via the environment:
#   CLAUDE_SANDBOX_HOME   where to clone   (default: ~/.local/share/claude-sandbox)
#   XDG_BIN_HOME          where to symlink (default: ~/.local/bin)
#   CLAUDE_SANDBOX_REPO   git URL to clone (default: the upstream repo)
set -eu

REPO_URL="${CLAUDE_SANDBOX_REPO:-https://github.com/aloony/claude-docker-sandbox.git}"
DATA_DIR="${CLAUDE_SANDBOX_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/claude-sandbox}"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"

say()  { printf '%s\n' "$*"; }
err()  { printf 'error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

have git || err "git is required but was not found on PATH."
if ! have docker; then
  say "warning: 'docker' was not found — install Docker (with the Compose plugin)"
  say "         before running claude-sandbox."
fi

# Clone fresh, or fast-forward an existing install in place.
if [ -d "$DATA_DIR/.git" ]; then
  say "updating existing install in $DATA_DIR"
  git -C "$DATA_DIR" pull --ff-only
else
  say "cloning into $DATA_DIR"
  mkdir -p "$(dirname "$DATA_DIR")"
  git clone --depth 1 "$REPO_URL" "$DATA_DIR"
fi

chmod +x "$DATA_DIR/claude-sandbox"

# Symlink the launcher onto PATH (the real file stays in the clone).
mkdir -p "$BIN_DIR"
ln -sf "$DATA_DIR/claude-sandbox" "$BIN_DIR/claude-sandbox"
say "linked $BIN_DIR/claude-sandbox -> $DATA_DIR/claude-sandbox"

# Nudge the user if the bin dir isn't on PATH yet.
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    say ""
    say "note: $BIN_DIR is not on your PATH. Add it, e.g.:"
    say "    echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> ~/.profile && . ~/.profile"
    ;;
esac

say ""
say "done. Try:  claude-sandbox example /path/to/your/repo"
say "Profiles live in $DATA_DIR/profiles — edit them and commit to your fork."
