FROM node:22-slim

# Core CLI tooling the agent reaches for most.
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      jq \
      less \
      openssh-client \
      procps \
      python3 \
      ripgrep

# Fuller dev toolset: compilers, Python tooling, editors, archives, extra
# search/view utilities, and network-debug tools. --no-install-recommends is
# kept for deterministic builds, not for image size (the list is explicit).
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      pkg-config \
      python3-dev \
      python3-pip \
      python3-venv \
      wget \
      vim \
      nano \
      unzip \
      zip \
      tree \
      file \
      rsync \
      sqlite3 \
      shellcheck \
      fzf \
      fd-find \
      bat \
      iproute2 \
      iputils-ping \
      dnsutils \
      netcat-openbsd \
  # Debian ships these under non-standard names; expose the usual ones.
  && ln -s "$(command -v fdfind)" /usr/local/bin/fd \
  && ln -s "$(command -v batcat)" /usr/local/bin/bat

# uv — fast Python package/project manager (preferred over pip/venv). Pulled
# from Astral's official image; pin the tag to lock the version if desired.
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# GitHub CLI (gh) — the harness uses it for PR/issue/API work. Ships from
# GitHub's own apt repo (pre-dearmored keyring), not Debian's.
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
  && apt-get update && apt-get install -y --no-install-recommends gh

# Audio capture for `/voice`. The CLI records the mic via (in order) a native
# napi module, `arecord` (ALSA), or SoX `rec`. The native path is gated on
# /proc/asound/cards (absent in this container), so we rely on arecord/rec and
# point ALSA's *default* PCM at PulseAudio. The host's PipeWire pulse socket is
# bind-mounted at runtime (see docker-compose.yml), so these ALSA tools reach
# the host sound server instead of trying to grab raw hardware.
#   - alsa-utils         -> arecord
#   - libasound2-plugins -> ALSA "pulse" plugin (pcm.pulse)
#   - sox + fmt-all      -> `rec` fallback
#   - pulseaudio-utils   -> pactl/pa* for debugging the link
RUN apt-get update && apt-get install -y --no-install-recommends \
      alsa-utils \
      libasound2-plugins \
      pulseaudio-utils \
      sox \
      libsox-fmt-all \
  && printf 'pcm.!default { type pulse }\nctl.!default { type pulse }\n' \
      > /etc/asound.conf

# sha512: sha512-C8T7H6qDIZLPzc4VChskMfq2nCjV9DU4zLcHtaK9rlQTt+cFCNPyzZ6FbMWiGQsQ9h4Z7nwdSZNhWEMPvfb5/g==
RUN npm install -g @anthropic-ai/claude-code@2.1.181

WORKDIR /claude
CMD ["claude"]
