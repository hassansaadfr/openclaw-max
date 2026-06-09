#!/usr/bin/env bash
set -euo pipefail

# 1) Materialize a stored Claude login from the runtime token. OpenClaw's
#    claude-cli backend clears auth env vars (CLAUDE_CODE_OAUTH_TOKEN, ...) before
#    spawning `claude`, forcing it to use a stored login. The setup-token is
#    long-lived (~1y), so we give it a far-future expiry and no refresh token —
#    nothing ever rotates.
if [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
  umask 077
  mkdir -p "$HOME/.claude"
  cat > "$HOME/.claude/.credentials.json" <<EOF
{"claudeAiOauth":{"accessToken":"${CLAUDE_CODE_OAUTH_TOKEN}","expiresAt":1900000000000,"scopes":["user:inference"],"subscriptionType":"max"}}
EOF
fi

# 2) Seed the OpenClaw config into the state dir if missing. When a persistent
#    volume is mounted at ~/.openclaw (e.g. on Coolify), a fresh volume starts
#    empty and would shadow the baked config — so copy the default template in.
mkdir -p "$HOME/.openclaw"
if [ ! -f "$HOME/.openclaw/openclaw.json" ]; then
  cp /usr/local/share/openclaw/openclaw.json "$HOME/.openclaw/openclaw.json"
fi

# 3) Allow the Control UI to be reached through a reverse proxy on a public domain
#    (Coolify, Traefik, ...). Without this the gateway rejects the request with
#    "Browser origin not allowed". Set OPENCLAW_ALLOWED_ORIGINS to a comma-separated
#    list of origins (scheme + host, no trailing slash), e.g.
#      OPENCLAW_ALLOWED_ORIGINS=https://openclaw.example.com
if [ -n "${OPENCLAW_ALLOWED_ORIGINS:-}" ]; then
  node -e '
    const fs = require("fs");
    const p = `${process.env.HOME}/.openclaw/openclaw.json`;
    const cfg = JSON.parse(fs.readFileSync(p, "utf8"));
    cfg.gateway = cfg.gateway || {};
    cfg.gateway.controlUi = cfg.gateway.controlUi || {};
    cfg.gateway.controlUi.allowedOrigins = process.env.OPENCLAW_ALLOWED_ORIGINS
      .split(",").map((s) => s.trim()).filter(Boolean);
    fs.writeFileSync(p, JSON.stringify(cfg, null, 2));
  '
fi

exec "$@"
