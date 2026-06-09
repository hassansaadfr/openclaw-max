<div align="center">

# 🦞 OpenClaw Max

### Your own AI assistant — powered by your **Claude subscription**, not the API.

Run [OpenClaw](https://openclaw.ai) on **Claude Opus 4.8** with a **1M-token context**,
through the Claude Code CLI. No API key. No per-token bill. Just the flat
subscription you already pay for.

![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)
![Base](https://img.shields.io/badge/base-official_OpenClaw_image-FF6B35)
![Model](https://img.shields.io/badge/Claude-Opus_4.8_·_1M-D97757)
![Auth](https://img.shields.io/badge/auth-subscription,_no_API_key-2ea44f)
![Deploy](https://img.shields.io/badge/deploy-Coolify_ready-8b5cf6)

</div>

---

## ✨ Why this exists

OpenClaw is a fantastic personal AI assistant. But wire it to Anthropic the usual
way and **every single message meters your API account, token by token**.

**OpenClaw Max flips that.** It plugs OpenClaw into the `claude` CLI, so inference
runs on your **Claude Pro/Max subscription** — the plan you're already paying for.
Same Opus 4.8, same 1M context, **zero metered API spend**.

```text
 agent main · session main · claude-cli/claude-opus-4-8 · tokens 29k/1.0m
 ❯ confirm you're working and name your model
   Working — Opus 4.8, running on your subscription. 🦞
```

## 🆚 API key vs. subscription

|                | Classic OpenClaw        | 🦞 **OpenClaw Max**              |
| -------------- | ----------------------- | -------------------------------- |
| **Auth**       | Anthropic API key       | Claude Pro/Max **subscription**  |
| **Billing**    | per token, metered 💸   | flat, already paid ✅            |
| **Backend**    | direct API              | the `claude` CLI (`claude-cli`)  |
| **Model**      | what you pay for        | **Opus 4.8 · 1M context**        |
| **Setup**      | paste an API key        | `claude setup-token`             |

## 🚀 Quick start

```bash
# 1. Build (overlays the official OpenClaw image)
docker build -t openclaw-max .

# 2. Get a 1-year subscription token (opens your browser, once)
claude setup-token
cp .env.example .env          # paste the token into CLAUDE_CODE_OAUTH_TOKEN

# 3. Run — drops straight into OpenClaw, already authenticated
docker run -it --rm --env-file .env openclaw-max
```

That's it. No login prompt, no theme picker, no trust dialog — it boots **ready**.

## 🧩 What you get

- 🔑 **No API key** — auth is your Claude subscription, via the CLI
- 🧠 **Opus 4.8 + 1M context** out of the box
- 🚪 **Starts ready** — onboarding, trust dialog and login all pre-handled
- 🛡️ **Non-root & hardened** — overlays the *official* OpenClaw image (tini, healthcheck, full plugin set: browser, canvas, voice…)
- ☁️ **VPS-ready** — gateway + Control UI, one `docker compose` away
- 🎛️ **Swappable model** — `--build-arg ANTHROPIC_MODEL=…` (default **Opus 4.8 · 1M**)
- 📌 **Pinnable** — `--build-arg OPENCLAW_VERSION=…` (default `latest`)

## ☁️ Deploy on a VPS (Coolify)

The bundled [`docker-compose.yml`](./docker-compose.yml) runs the **OpenClaw gateway
+ Control UI** — still on your subscription. Coolify's Traefik gives you the
**domain + automatic HTTPS**; the container only exposes its port on the internal
network, so the box only needs 80/443 open.

1. **New Resource → Docker Compose**, pointed at this repo.
2. Set a **domain** → Coolify issues the TLS cert automatically.
3. Add the environment variables:
   - `CLAUDE_CODE_OAUTH_TOKEN` — from `claude setup-token`
   - `OPENCLAW_GATEWAY_TOKEN` — a strong random token (`openssl rand -hex 32`)
   - `OPENCLAW_ALLOWED_ORIGINS` — your domain, e.g. `https://openclaw.example.com`
     (without it the gateway rejects the browser with *"Browser origin not allowed"*)
4. **Deploy.** State persists in a volume; access is gated by the gateway token.

## 🔧 How it works (the clever bit)

OpenClaw's `claude-cli` backend shells out to the real `claude` binary — but it
**strips every auth env var** before doing so, forcing `claude` to use a *stored
login*. So a tiny entrypoint turns your `CLAUDE_CODE_OAUTH_TOKEN` into exactly
that: a `~/.claude/.credentials.json` with a far-future expiry and no refresh
token, so nothing ever rotates. Running as the official image's **non-root user**
means `--dangerously-skip-permissions` just works — no escape hatches.

```
 your token ──▶ entrypoint ──▶ stored Claude login ──▶ claude CLI ──▶ Opus 4.8
                                                          ▲
                                          OpenClaw (claude-cli backend)
```

## ⚠️ Fair warning

Running a Claude subscription on an always-on server via the CLI is a grey area
under Anthropic's terms (there are headless / Agent-SDK usage limits). For a 24/7
public deployment, a dedicated API key is the cleaner, sanctioned path. Use this
for your own assistant, responsibly.

<div align="center">
<sub>Built with 🦞 OpenClaw + 🤖 Claude Code — the subscription way.</sub>
</div>
