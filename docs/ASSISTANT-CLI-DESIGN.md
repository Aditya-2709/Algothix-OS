# ALX Agent (`alx-agent`) — Lightweight Terminal Agent Design (`alx-profile-low`)

> **Status:** Design Only (no implementation yet). Intended as the low-RAM alternative to the Tauri/WebKitGTK desktop `alx-assistant` for 2–3 GB RAM laptops (`alx-profile-low`, e.g., Dell Vostro 1015).

## 1. Motivation
`alx-assistant` (Tauri + WebKitGTK + bundled Node.js v24) is too heavy for 2–3 GB RAM machines (~220–550 MB active RAM, plus ~600 MB disk/RAM if voice ONNX is loaded). Most troubleshooting, setup, and update workflows on ALX Lite happen in `urxvt`/`tmux` and do not need a WebView or screen capture.

## 2. Architecture
- **Runtime:** Single-file Python 3 CLI (using Debian `trixie` system `python3` + stdlib `urllib.request`/`json`, zero npm/Node/WebKitGTK/Electron dependencies) or small static Go/Rust binary.
- **Model Backend:** Cloud LLM over HTTPS using the user's own API key (Gemini, Claude, or OpenAI), read from `secret-tool` (`gnome-keyring`) or mode-`0600` `~/.config/alx-assistant/auth.json`. Requires internet; zero outbound calls until invoked.
- **Estimated Resource Footprint:**
  - **Idle RAM (not running):** `0 MB`
  - **Active RAM (during session):** **15–35 MB RSS** (Python 3 stdlib) or **8–18 MB RSS** (compiled Go/Rust binary) — roughly **10× lighter** than `alx-assistant`.
  - **Installed Disk Size:** **< 1 MB** (Python script) or **~4–8 MB** (static binary).

## 3. Strict Tool-Calling Allowlist
`alx-agent` never executes arbitrary shell commands (`bash -c` is forbidden). The model may only propose structured calls from a hardcoded allowlist:

| Allowed Tool | Read-Only / Mutating | Permitted Arguments | Confirmation Required |
|---|---|---|---|
| `alx-doctor --json` | Read-only | `--json` only | No (safe diagnostic) |
| `alx-setup list` | Read-only | `list` only | No |
| `alx-setup <profile> --dry-run` | Read-only | Known profile name + `--dry-run` | No |
| `alx-setup <profile>` | Mutating (APT) | Known profile name from `alx-setup list` | **Mandatory `[y/N]` prompt** |
| `alx-update --dry-run` | Read-only | `--dry-run` only | No |
| `alx-update` | Mutating (APT) | No extra flags | **Mandatory `[y/N]` prompt** |

## 4. Safety & Privacy Guarantees
- **Explicit Confirmation Gate:** Every mutating tool call prints the exact command, expected disk/RAM impact, and requires an explicit interactive `y` before execution (no `--auto-approve` flag by default).
- **Secret Redaction:** Before sending `alx-doctor` or log output to the cloud provider, redact tokens, API keys, private IPs/hostnames if configured, and never read `~/.ssh`, `~/.gnupg`, `~/.gg/auth.json`, or keyring files.
- **One-Key Abort:** `Ctrl+C` terminates the process immediately with no background daemon left running.
