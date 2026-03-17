# Agent Dev Container — Full development environment with autonomous runner
#
# Includes: Claude CLI, SSH, cron, Node.js, Python, git, ripgrep
# Pattern: multi-service container with root entrypoint for privileged services
#
# Build: docker compose build
# Run:   docker compose up -d
# SSH:   ssh -p 2222 claude@localhost

FROM debian:bookworm-slim

# Upgrade all packages to latest patched versions before installing anything
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

# System dependencies — the base toolkit for a Claude Code agent container
# curl/jq: API calls and JSON processing
# git/ripgrep: codebase operations (Claude Code uses rg internally)
# tini: PID 1 zombie reaper (critical — see ENTRYPOINT comment)
# openssh-server: remote access from any device
# cron: scheduled job execution
# python3: script runtime for API integrations
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl bash git ripgrep ca-certificates jq tini \
    openssh-server cron sudo \
    python3 python3-pip python3-venv \
    procps util-linux \
    && curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash \
    && apt-get install -y git-lfs \
    && git lfs install \
    && rm -rf /var/lib/apt/lists/*

# Node.js 22 (for Slack daemon + Claude Code runtime)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Non-root user — root entrypoint starts privileged services before dropping to this user
RUN useradd -m -s /bin/bash claude && usermod -aG crontab claude

# SSH: key-only auth, no passwords, no X11 forwarding
RUN mkdir /var/run/sshd \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config \
    && echo 'X11Forwarding no' >> /etc/ssh/sshd_config

# Generate SSH host keys (sshd refuses to start without them)
RUN ssh-keygen -A

# Python libraries — add your project-specific packages here
# Example: markdown for digest emails, tweepy for X posting
RUN pip3 install --break-system-packages markdown tweepy

# Optional: SQLCipher + build toolchain (for encrypted SQLite databases)
# Remove this block if your project doesn't need database encryption
RUN apt-get update && apt-get install -y --no-install-recommends \
    sqlcipher libsqlcipher-dev \
    build-essential python3-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Optional: Chromium deps for headless browser (Playwright/Puppeteer screenshots)
# Remove this block if you don't need browser automation inside the container
RUN apt-get update && apt-get install -y --no-install-recommends \
    libglib2.0-0 libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 libdbus-1-3 libdrm2 libxcomposite1 libxdamage1 \
    libxrandr2 libgbm1 libpango-1.0-0 libcairo2 libasound2 \
    libxshmfence1 libx11-6 libx11-xcb1 libxcb1 libxext6 libxfixes3 \
    fonts-liberation fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

# Switch to non-root user for remaining setup
USER claude
WORKDIR /home/claude

# SSH directory for authorized_keys mount
RUN mkdir -p /home/claude/.ssh && chmod 700 /home/claude/.ssh

# uv (Python package manager — faster than pip for project dependencies)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# 1Password CLI (for secret injection at container startup)
USER root
RUN apt-get update && apt-get install -y --no-install-recommends unzip && rm -rf /var/lib/apt/lists/*
USER claude
RUN mkdir -p /home/claude/.local/bin && \
    curl -sSfo /tmp/op.zip "https://cache.agilebits.com/dist/1P/op2/pkg/v2.32.1/op_linux_amd64_v2.32.1.zip" && \
    cd /tmp && unzip -q op.zip op -d /home/claude/.local/bin/ && \
    chmod +x /home/claude/.local/bin/op && \
    rm -f /tmp/op.zip

# Claude Code CLI
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/claude/.local/bin:${PATH}"
ENV DISABLE_AUTOUPDATER=1

# Cron schedule (installed by root entrypoint via crontab -u claude)
COPY --chown=claude:claude crontab /home/claude/.crontab

# Entrypoints — root wrapper starts sshd+cron, then drops to claude user
COPY --chown=claude:claude entrypoint.sh /home/claude/entrypoint.sh
RUN chmod +x /home/claude/entrypoint.sh
USER root
COPY docker-entrypoint-root.sh /usr/local/bin/docker-entrypoint-root.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-root.sh

EXPOSE 22 8000 8080

# tini as PID 1 — CRITICAL for zombie process reaping.
# Without tini, every `claude -p` call spawned by cron or the Slack daemon leaves
# a zombie node process. Bash doesn't call wait() on children, so zombies accumulate.
# tini acts as a proper init process that reaps orphaned processes automatically.
# MUST use exec form (JSON array) — shell form puts sh at PID 1, defeating the purpose.
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/docker-entrypoint-root.sh"]
