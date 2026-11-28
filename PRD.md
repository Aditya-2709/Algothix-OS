# Algothix OS (ALX) Lite — Product Requirements Document (Summary + Optional ALX Assistant)

## Core OS Requirements (v1.1–v1.3)
- **Target Hardware:** 64-bit x86_64 laptops with 2–4 GB RAM and spinning HDDs:
  - `alx-profile-low`: Dell Vostro 1015 (Core 2, 2–3 GB RAM, Intel GMA, no AES-NI)
  - `alx-profile-mid`: ASUS X541NA (Celeron N3350, 4 GB RAM, AES-NI)
- **Base & Desktop:** Debian 13 (`trixie`, `amd64`), X11-only (`SDDM` + `Awesome WM`, no compositor), idle RAM budget `≤ 450 MB`, `zram` (50% RAM), `earlyoom`, `ufw` default-deny incoming.
- **Core ALX Tools:** `alx-tune`, `alx-doctor`, `alx-setup`, `alx-update`, `alx-link` (Tailscale/WireGuard), `alx-cheatsheet`, signed `reprepro` APT repository.

## Optional Component: ALX Assistant (`alx-assistant`)
- **Distribution Policy:** **Never preinstalled** on any ALX Lite ISO or default profile. Published only to the ALX APT **`testing`** channel until hardware/QEMU and license reviews pass.
- **Installation & Removal:** Installed on demand via `alx-setup assistant` (supports `--dry-run` and `--remove`). Prominently offered only on `alx-profile-mid` (4 GB+ RAM); displays an explicit warning on `alx-profile-low` or `< 3 GB RAM`.
- **Cloud-Only / Bring Your Own Key (BYOK):** Local LLMs are out of scope on target hardware. Requires internet access and the user's own API key (Gemini, Claude, or ChatGPT). Zero network traffic is allowed before a key is configured; zero inbound firewall ports are opened.
- **Safety & Privacy Defaults:** `allowActions=false`, `skipAllow=false`, `rawReadOnly=true`, `telemetry=false`, no auto-updater, `0600` credential/config permissions (with `gnome-keyring` / `secret-tool` support), visible Awesome WM wibar warning (`AI: ACT!`) whenever actions are enabled, and one-key panic stop (`Mod4+Shift+Escape`).
- **Low-Profile Alternative:** For `alx-profile-low` (2–3 GB RAM), a minimal terminal agent (`alx-agent`, ~15–35 MB RAM) is designed in `docs/ASSISTANT-CLI-DESIGN.md`.
