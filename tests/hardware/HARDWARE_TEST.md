# Algothix OS (ALX) Lite — Physical Hardware Test Checklist (v1.1)

Run this checklist on physical reference hardware before signing off a v1.1 release.

## Reference Machines

| Machine | Specs | Expected ALX Profile |
|---|---|---|
| **Dell Vostro 1015** | Core 2 era x86_64, 2–3 GB RAM, Intel GMA, HDD, no AES-NI | `alx-profile-low` |
| **ASUS X541NA** | Intel Celeron N3350, 4 GB RAM, AES-NI, HDD/SSD | `alx-profile-mid` |

---

## Test Checklist

### 1. Live Boot, SDDM & Awesome WM
- [ ] **BIOS boot (Vostro 1015):** USB boots cleanly into ISOLINUX menu (`Algothix OS (ALX) Lite`).
- [ ] **UEFI boot (ASUS X541NA):** USB boots cleanly into GRUB menu (`Algothix OS (ALX) Lite`).
- [ ] **SDDM & Awesome WM:** Live ISO auto-logs into Awesome WM with the 28px top wibar (5 tags + RAM/CPU/NET/BAT/LINK/clock) and PNG ASCII `"ALX"` wallpaper. Logging out (`Super+Shift+e`) shows the minimal `alx` SDDM login card (`#0B0D10`, `#3DDC97`, JetBrains Mono clock, no GPU glitches).
- [ ] **Wi-Fi & Suspend/Resume:** `nm-applet` connects to Wi-Fi (`non-free-firmware`); suspend/resume works cleanly.

### 2. Installation (Calamares)
- [ ] **Vostro 1015 (no AES-NI):** `alx-calamares-launch` disables LUKS encryption with warning; ext4 install completes in `< 20 min`.
- [ ] **ASUS X541NA (AES-NI):** `alx-calamares-launch` enables optional LUKS; ext4 install completes in `< 20 min`.
- [ ] **Post-install first boot:** SDDM prompts for password (live autologin removed), `alx-tune.service` runs automatically, and `alx-welcome` prints on first terminal login.

### 3. Performance Budgets & Security
- [ ] **Boot time (`systemd-analyze`):** `< 45 s` on HDD (Vostro: `____ s`, ASUS: `____ s`).
- [ ] **Idle RAM (`free -m`, Awesome WM after login):** `< 450 MB` (Vostro: `____ MB`, ASUS: `____ MB`).
- [ ] **zram & earlyoom:** `swapon --show` shows `/dev/zram0` (zstd, 50%); `alx-doctor` returns `OK`.
- [ ] **Security:** `ss -tulpn` shows zero externally listening ports before pairing; `sudo ufw status` is active (deny incoming).

### 4. Developer & ALX Link Workflow (1-Hour Session)
- [ ] **Dev tools:** `nvim`, `tmux`, `zsh`, `git`, `lazygit`, `podman run --rm hello-world`, and `alx-setup python --dry-run` work.
- [ ] **ALX Link (Vostro ↔ ASUS):**
  - [ ] `alx-link pair` completes with 6-digit PIN; `ssh <peer>` works.
  - [ ] `alx-link send <file> <peer>` (Taildrop on Tailscale, `rsync`/`scp` on WireGuard) works.
  - [ ] `~/ALX-Sync` syncs via Syncthing (`Nice=10`, idle I/O).
  - [ ] `alx-link clip <peer>` and `alx-link notify <peer> "test"` work on the remote desktop.
  - [ ] `alx-link run <peer> -- uname -a` runs inside remote `tmux`.
  - [ ] `alx-link unpair <peer>` cleanly removes peer config, keys, and Syncthing device.
- [ ] **Optional LocalSend check:** Test `alx-setup localsend` on ASUS (`alx-profile-mid`) and verify software-rendering usability on Vostro (`alx-profile-low`).
- [ ] **1-Hour Coding Session (Vostro 1015):** `nvim` + `tmux` + Git + 5-tab Firefox ESR without freeze or OOM crash.

### 5. Optional ALX Assistant Verification (ASUS X541NA Recommended; Caution on Vostro 1015)
- [ ] **Non-inclusion check:** Confirm `dpkg -l alx-assistant` is NOT installed on a fresh ISO boot.
- [ ] **Install via `alx-setup assistant`:** Confirm warning prints on `alx-profile-low` (Vostro 1015) and zero inbound `ufw` ports are opened (`sudo ufw status`).
- [ ] **No-network-before-key check:** Run `ss -tunp` before entering an API key; confirm 0 outbound assistant connections.
- [ ] **First-run setup & real API key:** Run `alx-assistant --setup`, enter your personal Gemini/Claude/ChatGPT key, verify `0600` permissions on `~/.config/alx-assistant/settings.json` and `~/.gg/auth.json`.
- [ ] **Desktop integration:** Verify `Super+i`, `Super+Shift+i`, `Super+Shift+Esc` (panic stop), and the top wibar `AI: off / listen / ACT!` badge.
- [ ] **Real hardware voice & GPU check (unverified in QEMU):** Test ALSA microphone capture/playback and WebKitGTK rendering on Intel GMA (Vostro 1015) and Celeron N3350 (ASUS X541NA).
- [ ] **Clean removal:** Run `sudo alx-setup assistant --remove` and verify package removal preserves `~/.config/alx-assistant`.
