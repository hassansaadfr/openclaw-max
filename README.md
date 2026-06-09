# OpenClaw + Claude Code — Docker (subscription via the CLI)

Runs [OpenClaw](https://openclaw.ai) on your **Claude subscription** through the
[Claude Code](https://code.claude.com) CLI (the `claude-cli` backend — **no API
key, no per-token billing**). Default model: **Claude Opus 4.8 with a 1M context
window**.

It **overlays the official OpenClaw image** (`ghcr.io/openclaw/openclaw`) — a
maintained, non-root, hardened base with `tini`, a built-in healthcheck and the
full plugin set (browser, canvas, voice, …) — and just adds Claude Code plus the
subscription wiring. Locally it boots straight into the OpenClaw TUI; on a VPS it
runs the gateway + Control UI.

## What's inside

| Component | Notes |
| --------- | ----- |
| Base | `ghcr.io/openclaw/openclaw` (Debian 12, non-root `node` user) |
| OpenClaw version | via `ARG OPENCLAW_VERSION` (the image tag), default `latest` |
| Claude Code (`claude`) | added on top; used as OpenClaw's model backend |
| Default model | `claude-opus-4-8`, 1M context (`ANTHROPIC_MODEL=claude-opus-4-8[1m]`) |

## Prerequisites

- Docker
- A Claude Pro/Max subscription

## 1. Build

```bash
cd ~/code/claude-code-docker
docker build -t claude-openclaw .
# pin the OpenClaw version if you want:
# docker build --build-arg OPENCLAW_VERSION=2026.6.5 -t claude-openclaw .
```

## 2. Authenticate (subscription token)

Generate a long-lived OAuth token **on your host** (opens a browser, authorizes
against your Pro/Max subscription):

```bash
claude setup-token
```

Copy the example env file and paste the token into it:

```bash
cp .env.example .env
# then edit .env →  CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat...
```

`.env` is gitignored — **never commit it**. The token is valid for **1 year**.

## 3. Run locally

**OpenClaw TUI, on your subscription:**

```bash
docker run -it --rm --env-file .env claude-openclaw
```

**Use Claude Code directly instead** (the wrapper still runs first):

```bash
docker run -it --rm --env-file .env -v "$(pwd):/workspace" claude-openclaw claude
docker run --rm    --env-file .env -v "$(pwd):/workspace" claude-openclaw claude -p "Say hello"
```

## 4. Deploy on a VPS with Coolify

The bundled `docker-compose.yml` runs the **OpenClaw gateway + Control UI** (still
on your subscription via `claude-cli`). Coolify's Traefik provides the **domain +
HTTPS**; the container only exposes the gateway port on the internal network, so
your VPS firewall only needs 80/443.

1. **New Resource → Docker Compose**, pointed at this repo (Coolify builds the
   `Dockerfile`). It runs `openclaw gateway --auth token --bind lan --port 18789`.
2. **Set a domain** (e.g. `openclaw.example.com`) → Coolify issues a Let's Encrypt
   cert automatically. Set the **exposed port to `18789`** if asked.
3. **Environment Variables** (secrets):
   - `CLAUDE_CODE_OAUTH_TOKEN` — from `claude setup-token`
   - `OPENCLAW_GATEWAY_TOKEN` — a strong random token (`openssl rand -hex 32`)
4. **Deploy.** State persists in the `openclaw-state` volume
   (`/home/node/.openclaw`). Health is reported on `/healthz`.

**Security model:**

- **HTTPS + domain** → Coolify / Traefik.
- **Access control** → the gateway runs `--auth token`; nobody reaches it without
  `OPENCLAW_GATEWAY_TOKEN`, even though the domain is public. (OpenClaw's UI itself
  is plain HTTP + token, so the TLS *must* come from the proxy — which it does.)
- **No host exposure** → the compose uses `expose:` (internal only), not `ports:`.
- **Optional extra layers** → Coolify Basic Auth, IP allowlist, or Tailscale.

> Running a Claude subscription on an always-on server via the CLI is a grey area
> under Anthropic's terms (headless/Agent-SDK usage limits). For a 24/7 public
> deployment, a dedicated API key is the cleaner, sanctioned path.

## How it works

**Runs on the subscription via the CLI, not the API.** OpenClaw's `claude-cli`
backend shells out to the in-image `claude` binary. Two details make it work
non-interactively:

- OpenClaw deliberately **clears auth env vars** (`CLAUDE_CODE_OAUTH_TOKEN`,
  `ANTHROPIC_API_KEY`, …) before spawning `claude`, forcing it to use a *stored*
  login. So `entrypoint.sh` materializes `~/.claude/.credentials.json` from
  `CLAUDE_CODE_OAUTH_TOKEN` at startup, with a far-future expiry and **no refresh
  token** — nothing rotates. (`$HOME` is `/home/node` here.)
- The official base runs as **non-root `node`**, so `claude
  --dangerously-skip-permissions` is allowed without any escape hatch.

Model selection lives in `openclaw.json` (`anthropic/claude-opus-4-8` via
`agentRuntime.id: "claude-cli"`, plus `gateway.mode: local`), seeded into the
state dir on first start so a fresh persistent volume still gets it.
`ANTHROPIC_MODEL=claude-opus-4-8[1m]` selects the 1M context window.

**Starts ready.** A pre-seeded `claude.json` at `/home/node/.claude.json` marks
onboarding complete, sets the theme, and pre-accepts the trust dialog — no
first-run prompts.

## Updating OpenClaw

```bash
docker build --pull --build-arg OPENCLAW_VERSION=latest -t claude-openclaw .
# or pin a specific tag from: https://github.com/openclaw/openclaw/pkgs/container/openclaw
```

## Verify the build

```bash
docker run --rm --entrypoint claude   claude-openclaw --version
docker run --rm --entrypoint openclaw claude-openclaw --version
```
