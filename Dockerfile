# OpenClaw + Claude Code, running on your Claude subscription via the Claude CLI
# (the claude-cli backend — no API key). This overlays the OFFICIAL OpenClaw image
# (non-root `node` user, tini, built-in healthcheck, full plugin set) with Claude
# Code and the subscription/CLI wiring.
#
# Override the OpenClaw version at build time:
#   docker build --build-arg OPENCLAW_VERSION=2026.6.5 .
ARG OPENCLAW_VERSION=latest
FROM ghcr.io/openclaw/openclaw:${OPENCLAW_VERSION}

# Add Claude Code (+ ripgrep). Needs root to write the global npm prefix (/usr/local).
USER root
RUN npm install -g @anthropic-ai/claude-code \
    && apt-get update && apt-get install -y --no-install-recommends ripgrep \
    && rm -rf /var/lib/apt/lists/*

# Pre-seed Claude Code onboarding/trust config for the node user, the OpenClaw
# config template (seeded into the state dir by the wrapper), and the wrapper.
# Running as the image's non-root `node` user means
# `claude --dangerously-skip-permissions` is allowed natively (no root override).
COPY claude.json /home/node/.claude.json
COPY openclaw.json /usr/local/share/openclaw/openclaw.json
COPY --chmod=0755 entrypoint.sh /usr/local/bin/claude-entrypoint.sh
RUN chown node:node /home/node/.claude.json

# Default model: Claude Opus 4.8, 1M context.
ENV ANTHROPIC_MODEL="claude-opus-4-8[1m]"

USER node

# The wrapper runs first (turns CLAUDE_CODE_OAUTH_TOKEN into a stored Claude login
# and seeds the OpenClaw config), then hands off to the image's init (tini).
# Default command boots the OpenClaw terminal UI; the compose file overrides it
# with the gateway for a Coolify/VPS deployment.
ENTRYPOINT ["/usr/local/bin/claude-entrypoint.sh", "tini", "-s", "--"]
CMD ["openclaw", "chat", "--local"]
