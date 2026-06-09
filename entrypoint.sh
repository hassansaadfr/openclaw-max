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

exec "$@"
