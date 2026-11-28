# ALX Assistant — Upstream Evaluation (`EricTechPro/jarvis`)

- **Evaluated Upstream:** [EricTechPro/jarvis](https://github.com/EricTechPro/jarvis)
- **Pinned Commit / Tag:** `af7465f` (`main`, tag `Jarvis v0.2.12`)
- **Upstream License:** GNU Affero General Public License v3.0 (`AGPL-3.0`)
- **Evaluation Date:** 2026-11-28
- **Target Platform:** Algothix OS (ALX) Lite — Debian 13 (`trixie`, `amd64`), X11 (`SDDM` + `Awesome WM`, no compositor), 2–4 GB RAM, HDD

---

## Executive Go / No-Go Verdict

**Conditional GO (Optional `testing` channel only — NEVER preinstalled, NOT recommended on `alx-profile-low` / <3 GB RAM).**

1. **X11 / Awesome WM works for overlay, hotkeys, and screen capture**, including explicit non-composited X11 handling (`shape_combine_region` in `showcase/tauri/src-tauri/src/linux.rs`) so transparent areas do not render black on Awesome WM.
2. **Three material blockers/caveats must be handled before shipping:**
   - **Node.js version gap in Debian 13 (`trixie`):** Upstream `showcase/tauri/sidecar/package.json` requires `engines.node >= 22` and bundles Node.js `v24.22.2` via `fetch-node.sh`. Debian `trixie` ships [`nodejs` `20.19.2+dfsg-1+deb13u3`](https://packages.debian.org/trixie/nodejs), which does **not** satisfy `>=22`. The Debian package must bundle an official SHA-256-verified Node.js 22+ binary (recorded in `docs/THIRD_PARTY.md`).
   - **No Linux GUI click/type (`hands`) helper upstream:** `AGENTS.md` and `showcase/tauri/sidecar/platform.mjs` explicitly mark Linux as **beta** with `hasHands: false` (*"Linux has no hands helper yet"*), `canSnap: false`, and `canCircle: false`. Screen capture and hotkeys work on X11, but GUI click/type automation is not implemented upstream on Linux.
   - **License & supply-chain risks:** `THIRD_PARTY_NOTICES.md` includes `@anthropic-ai/claude-agent-sdk` (marked **Proprietary**) alongside `AGPL-3.0-only` code, `tauri.conf.json` disables CSP (`"csp": null`), `Cargo.toml` still links `tauri-plugin-updater`, and Linux/Windows voice mode triggers a one-time Hugging Face download of the NVIDIA Parakeet TDT 0.6B v3 ONNX model (significant disk/RAM cost on 2–4 GB laptops).

---

## Detailed Code-Evidenced Findings (a–h)

### (a) Does it build and run on Debian 13 (`trixie`) amd64 under X11?
- **Partially yes (with bundled Node.js 22+ and `libasound2t64` dependency fix):**
  - App sources live under `showcase/tauri/` (`src-tauri/` Tauri 2 Rust shell + `sidecar/` Node.js sidecar + `showcase/jarvis/` shared JS).
  - `AGENTS.md` confirms Linux builds `.deb`/AppImage/RPM on Ubuntu 24.04 because ONNX Runtime requires **glibc 2.38+**. Debian 13 (`trixie`) ships glibc 2.41, satisfying this requirement.
  - `showcase/tauri/sidecar/platform.mjs` explicitly supports X11 (`linuxSession` checks `JARVIS_SESSION`, `XDG_SESSION_TYPE`, `WAYLAND_DISPLAY`, defaulting to `'x11'`), with `seesPointer: true` and `hasHotkeys: true`.
  - `showcase/tauri/src-tauri/src/linux.rs` (lines 93–97) detects non-composited X11 window managers (`!win.screen().is_composited()`) and applies `win.shape_combine_region(Some(&region), 0, 0)` plus `input_shape_combine_region` for click-through overlays, matching ALX Lite's compositor-free Awesome WM setup.
  - Upstream `showcase/tauri/src-tauri/tauri.linux.conf.json` declares `libasound2`, which must be updated to [`libasound2t64`](https://packages.debian.org/trixie/libasound2t64) on Debian 13 (`trixie`).

### (b) Exact Build & Runtime Dependencies (Debian 13 `trixie` Availability)

| Dependency | Upstream Requirement | Debian 13 (`trixie`) Package / Version | Status in `trixie` |
|---|---|---|---|
| **Rust / Cargo** | Rust edition 2021 (`Cargo.toml`), Tauri `=2.12.5`, `tauri-build =2.7.6` | [`rustc`](https://packages.debian.org/trixie/rustc) `1.85.1+dfsg1-1+deb13u1` (or `1.96.1` in `trixie-backports`) | In `trixie` (verify MSRV during container build; `trixie-backports` available if crates require >1.85) |
| **Node.js** | `engines.node >= 22` (upstream bundles `v24.22.2` via `fetch-node.sh`) | [`nodejs`](https://packages.debian.org/trixie/nodejs) `20.19.2+dfsg-1+deb13u3` | **NOT satisfied** — must bundle SHA-256-verified official Node.js 22 LTS / 24 binary |
| **WebKitGTK** | Tauri 2 Linux webview (`webkit2gtk-4.1`) | [`libwebkit2gtk-4.1-0`](https://packages.debian.org/trixie/libwebkit2gtk-4.1-0) & [`libwebkit2gtk-4.1-dev`](https://packages.debian.org/trixie/libwebkit2gtk-4.1-dev) (`2.54.3-1~deb13u1`) | In `trixie` |
| **GTK 3** | `gtk = "=0.18.2"` in `Cargo.toml` | [`libgtk-3-0t64`](https://packages.debian.org/trixie/libgtk-3-0t64) (`3.24.49-3`) & `libgtk-3-dev` | In `trixie` |
| **ALSA Audio** | `voice-win` ALSA mic (`libasound2` in `tauri.linux.conf.json`) | [`libasound2t64`](https://packages.debian.org/trixie/libasound2t64) (`1.2.14-1+deb13u1`) | In `trixie` (renamed `t64`) |
| **X11 / D-Bus Crates** | `x11rb = "=0.14.0"`, `zbus = "=6.5.0"`, `global-hotkey = "=0.10.0"` | Compiled via Cargo; runtime uses `libx11-6`, `dbus` | In `trixie` |
| **Keyring / Secrets** | `secret-tool` (`libsecret-tools` in `recommends`) | [`gnome-keyring`](https://packages.debian.org/trixie/gnome-keyring) (`48.0-1`) + `libsecret-tools` | In `trixie` |
| **X11 Input Tool** | Optional/future X11 automation helper | [`xdotool`](https://packages.debian.org/trixie/xdotool) (`1:3.20160805.1-5.1`) | In `trixie` |

### (c) Screen Capture, Mouse Clicks, and Keyboard Typing on Linux
- **Screen Capture (X11):** Implemented natively in `showcase/tauri/src-tauri/src/linux.rs` (lines 337–353) via GTK3/GDK `grab_root()`: `gtk::gdk::Window::default_root_window().pixbuf(0, 0, root.width(), root.height())`, scaled and saved as JPEG (`quality: 85`) via `save_fitted()`. Does **not** require `scrot` or `grim` on X11. On Wayland, falls back to `org.freedesktop.portal.Screenshot` over `zbus`.
- **Pointer State (X11):** `linux.rs` (lines 198–232) queries pointer/modifier state via `x11rb` (`conn.query_pointer(x.root)`).
- **Clicks & Typing:** **Not implemented on Linux upstream.** `AGENTS.md` and `showcase/tauri/sidecar/platform.mjs` confirm `hasHands: false` (*"Linux has no hands helper yet"*). `xdotool` is declared in `packages/alx-assistant/debian/control` for future X11 action support and panic/focus helpers, while `allowActions` remains `false` by default.

### (d) API Keys and Settings Storage
- **Settings & Local Data:** `showcase/tauri/sidecar/store.mjs` writes `settings.json`, `memory.json`, `sessions/`, `logs/`, `usage.jsonl`, and `jobs.json` under `~/Jarvis/Data/` (remapped to `~/.config/alx-assistant/` / `~/ALX-Assistant/Data/` in our wrapper/fork) using atomic JSON writes with directory mode `0700` and file mode `0600`.
- **AI Provider API Keys / OAuth:** `SECURITY.md` documents reading AI provider keys from `~/.gg/auth.json`. Our `alx-assistant-setup` wizard stores keys in the Secret Service keyring (`secret-tool` + `gnome-keyring`) when available and enforces `chmod 600` (`umask 077`) on `~/.gg/auth.json` and `~/.config/alx-assistant/auth.json`.
- **Other Secrets (Fish Audio / Memory Sync):** `showcase/tauri/sidecar/secrets.mjs` uses `secret-tool` (`libsecret-tools`) on Linux with **no plain-text fallback** (except under `JARVIS_DATA_DIR` test mode). Under Awesome WM, `gnome-keyring-daemon` must be running for `secret-tool` to succeed.
- **Secret Read Denylist:** `showcase/tauri/sidecar/safety.mjs` (lines 11–26) explicitly blocks agent file-reads of `~/.ssh`, `~/.gnupg`, `~/.aws`, `~/.azure`, `~/.kube/config`, `~/.docker/config.json`, `~/.netrc`, `~/.npmrc`, `~/.pypirc`, `~/.git-credentials`, `~/.config/gh`, `~/.config/gcloud`, `~/.gg/auth.json`, `Jarvis/Data/secrets.json`, GNOME keyring, KDE wallet, `pass`, NSS cert store, and Firefox logins/cookies.

### (e) Outbound Network Destinations
Documented in `PRIVACY.md` and `THIRD_PARTY_NOTICES.md` (no developer analytics/telemetry servers):
1. **User-selected LLM provider APIs:** Google Gemini (`@google/genai`), Anthropic Claude (`@anthropic-ai/claude-agent-sdk`), OpenAI ChatGPT, or local Ollama/LM Studio (not viable on ALX Lite).
2. **TTS providers (when voice enabled):** Fish Audio or Google (Gemini TTS).
3. **Hugging Face:** One-time download of NVIDIA Parakeet TDT 0.6B v3 ONNX speech recognition model on Linux/Windows (voice mode).
4. **GitHub:** Optional skill downloads; optional Claude Code download upon Claude sign-in.
5. **Web/Tool lookups (when triggered by user query):** Wikipedia (photo cards), target websites' `favicon.ico` (source cards), `web_fetch` URLs, `web_search` engines (Anthropic, DuckDuckGo, Brave, Bing, Google), and user-configured MCP servers.

### (f) Default Safety Settings & Enforcement
- **Documented Defaults (`README.md`):** `allowActions: false`, `skipAllow: false`, `rawReadOnly: true`, `telemetry: false`.
- **Secret Path Guard:** Enforced in `showcase/tauri/sidecar/safety.mjs` (lines 11–26).
- **ALX Hardening:** Our `/usr/bin/alx-assistant` wrapper initializes `~/.config/alx-assistant/settings.json` with `allowActions=false`, `skipAllow=false`, `rawReadOnly=true`, `telemetry=false` (`0600`) on first run and exports state to `/run/user/$UID/alx-assistant.state` so the Awesome WM wibar flashes a red `AI: ACT!` indicator whenever `allowActions=true`.
- **Unverified Detail (Flagged for Fork Audit):** Exact line numbers inside the 3,219-line `showcase/tauri/sidecar/sidekick.mjs` enforcing `allowActions`/`skipAllow`/`rawReadOnly` were not directly read due to browser session pagination limits and must be grepped during the Codespaces fork clone (`ci/prepare-alx-assistant-fork.sh` prints those exact lines).

### (g) Hotkeys and Configuration
- **Upstream Defaults (`showcase/tauri/sidecar/platform.mjs`, `global-hotkey = "=0.10.0"`):**
  - Talk: `Ctrl + Alt` (`['control', 'option']`)
  - Type: `Ctrl + Shift` (`['control', 'shift']`)
  - Show: `Ctrl + Shift + S`
- **Awesome WM Audit (`packages/alx-desktop-awesome/etc/skel/.config/awesome/rc.lua`):**
  - Awesome WM uses `Mod4` (`Super`) for all window management (`Mod4+Enter`, `Mod4+d`, `Mod4+e`, `Mod4+h/j/k/l`, `Mod4+1..5`, `Mod4+Ctrl+h/l`).
  - `Ctrl+Alt` and `Ctrl+Shift` frequently collide with terminal (`urxvt`), VS Code (`Ctrl+Shift+P`), and Brave (`Ctrl+Shift+T`) shortcuts.
  - **ALX Resolution:** Configurable via `~/.config/alx-assistant/hotkeys.env` with conflict-free defaults: `Mod4+a` (toggle/talk), `Mod4+Shift+a` (type prompt), and `Mod4+Shift+Escape` (one-key panic stop).

### (h) Suspicious or Risky Findings
1. **CSP Disabled (`tauri.conf.json`):** `"csp": null` and `"withGlobalTauri": true` expose Tauri IPC to any untrusted web content rendered in the WebView. **Mitigation:** Set a strict `default-src 'self'` CSP in the ALX fork.
2. **Updater Crate Still Linked (`Cargo.toml`):** `tauri-plugin-updater = "=2.14.1"` is listed in `Cargo.toml` even though `createUpdaterArtifacts` is `false`. **Mitigation:** Strip `tauri-plugin-updater` from `Cargo.toml` and Rust initialization in `ci/prepare-alx-assistant-fork.sh`.
3. **Proprietary SDK inside AGPL-3.0 App (`THIRD_PARTY_NOTICES.md`):** `@anthropic-ai/claude-agent-sdk` is proprietary. Redistributing it bundled inside an AGPL-3.0 `.deb` raises license-compatibility concerns. **Mitigation:** Maintainer must review before promoting from `testing` to `stable` (or strip the proprietary SDK and use standard HTTPS/SDK calls).
4. **Runtime Model/Binary Downloads:** One-time Hugging Face download of Parakeet TDT 0.6B v3 ONNX (~600 MB+) and optional Claude Code download on Claude sign-in could exhaust disk/RAM on 2–4 GB laptops. **Mitigation:** Disable automatic model downloads on startup; document clearly in `alx-setup assistant` and `USER_GUIDE.md`.
5. **Untrusted Shell/File Execution if `allowActions=true`:** `SECURITY.md` warns the agent can run commands and write files when actions are enabled. **Mitigation:** Keep `allowActions=false`, `skipAllow=false`, `rawReadOnly=true` by default, display a red wibar badge when enabled, and bind `Mod4+Shift+Escape` to `alx-assistant --panic-stop`.

---

## Measured Resource Usage (QEMU 2 GB & 4 GB RAM)

> **Honesty Note:** The offline build sandbox does not have `qemu-system-x86_64`, `docker`, or outbound internet to build the Tauri binary. Run `./tests/qemu/measure-assistant.sh` in GitHub Codespaces / Docker to populate the exact measured numbers below before promoting `alx-assistant` out of `testing`.

| Metric | 2 GB RAM QEMU (`alx-profile-low`) | 4 GB RAM QEMU (`alx-profile-mid`) | Target / Budget |
|---|---|---|---|
| Idle RAM before install (`free -m`) | `PENDING QEMU RUN` | `PENDING QEMU RUN` | ≤ 450 MB |
| Idle RAM after install (not running) | `PENDING QEMU RUN` | `PENDING QEMU RUN` | ≤ 450 MB (delta ~0 MB) |
| RAM while ALX Assistant running idle (WebKitGTK + Node sidecar) | `PENDING QEMU RUN` *(est. +220–380 MB)* | `PENDING QEMU RUN` *(est. +220–380 MB)* | Warn if > 300 MB delta |
| RAM during text/voice interaction (mock endpoint) | `PENDING QEMU RUN` *(est. +300–550 MB; +800 MB+ if Parakeet ONNX loaded)* | `PENDING QEMU RUN` | Must not trigger `earlyoom` |
| Installed disk size (`.deb` + bundled Node + deps) | `PENDING QEMU RUN` *(est. ~180–260 MB without ONNX model)* | `PENDING QEMU RUN` | Documented in `alx-setup` |
| Outbound connections before API key is set (`ss`/`tcpdump`) | `PENDING QEMU RUN` | `PENDING QEMU RUN` | **0 connections** |

## Unverified Items Requiring Manual / Hardware Testing
- Full 40-character upstream commit SHA (short SHA `af7465f` verified via GitHub web inspection; full SHA captured by `ci/prepare-alx-assistant-fork.sh`).
- Exact `sidekick.mjs` enforcement lines and full grep of hardcoded URLs across all `.mjs`/`.rs` files (automated in `ci/prepare-alx-assistant-fork.sh`).
- Real hardware testing on **Dell Vostro 1015** (Core 2 / Intel GMA software rendering / 2–3 GB RAM) and **ASUS X541NA** (Celeron N3350 / 4 GB RAM).
- Voice microphone input/ALSA playback on physical laptop hardware and real API key interaction (Gemini/Claude/ChatGPT).
- Wayland (explicitly out of scope for ALX Lite X11).
