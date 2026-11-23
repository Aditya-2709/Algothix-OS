# Algothix OS (ALX) Lite — Physical Hardware Test Checklist

Run this checklist on physical reference hardware before signing off a v1.0 release (PRD Section 11 & Section 15).

## Reference Machines

| Machine | Specs | Expected ALX Profile |
|---|---|---|
| **Dell Vostro 1015** | Core 2 era x86_64, 2–3 GB RAM, Intel GMA, HDD, no AES-NI | `alx-profile-low` |
| **ASUS X541NA** | Intel Celeron N3350, 4 GB RAM, AES-NI, HDD/SSD | `alx-profile-mid` |

---

## Test Checklist (Mark PASS / FAIL and Record Measurements)

### 1. Live Boot & Hardware Detection
- [ ] **BIOS boot (Vostro 1015):** USB boots cleanly into branded ISOLINUX menu (`Algothix OS (ALX) Lite`).
- [ ] **UEFI boot (ASUS X541NA):** USB boots cleanly into branded GRUB menu (`Algothix OS (ALX) Lite`).
- [ ] **Graphics:** Xorg + LightDM + ALX-i3 renders without black screen or severe tearing. If Intel GMA glitches, verify **Safe Graphics (nomodeset)** menu entry boots cleanly.
- [ ] **Wi-Fi & Ethernet:** `nm-applet` detects Wi-Fi networks (`non-free-firmware` loaded) and connects cleanly.
- [ ] **Audio & Suspend/Resume:** Laptop suspends cleanly (`systemctl suspend`) and resumes with working display and Wi-Fi.

### 2. Installation (Calamares)
- [ ] **Vostro 1015 (no AES-NI):** `alx-calamares-launch` warns and disables LUKS disk encryption option; ext4-only guided install completes in **< 20 min** (record time: `____ min`).
- [ ] **ASUS X541NA (AES-NI):** `alx-calamares-launch` enables optional LUKS encryption; ext4 install completes in **< 20 min** (record time: `____ min`).
- [ ] **Post-install first boot:** Installed system boots without USB, `alx-tune.service` runs automatically, `/etc/alx/profile` matches expected profile, and `alx-welcome` prints on first terminal login.

### 3. Performance Budgets & Diagnostics
- [ ] **Boot time (`systemd-analyze`):** `< 45 s` on HDD (record Vostro: `____ s`, ASUS: `____ s`).
- [ ] **Idle RAM (`free -m`, used column, ALX-i3 after login):** `< 450 MB` (record Vostro: `____ MB`, ASUS: `____ MB`).
- [ ] **zram & earlyoom:** `swapon --show` shows `/dev/zram0` (50% RAM, zstd); `systemctl is-active earlyoom` returns `active`.
- [ ] **ALX Doctor:** `alx-doctor` returns `Overall status: OK (fail=0)`.
- [ ] **Security:** `ss -tulpn` shows zero externally listening ports on fresh install; `sudo ufw status` shows `Status: active` (deny incoming).

### 4. Developer & Cross-Device Workflow (1-Hour Real Session)
- [ ] **Editors & Dev:** `nvim`, `tmux`, `zsh`, `git`, `lazygit`, and `podman run --rm hello-world` all work smoothly.
- [ ] **ALX Setup:** `alx-setup python --dry-run` and `alx-setup python` succeed.
- [ ] **ALX Link (Vostro ↔ ASUS):**
  - [ ] `alx-link pair` completes with 6-digit PIN confirmation.
  - [ ] `ssh <peer>` connects without password.
  - [ ] File added to `~/ALX-Sync` syncs via Syncthing between both laptops.
  - [ ] `alx-link run <peer> -- uname -a` executes inside remote `tmux`.
  - [ ] Input Leap keyboard/mouse sharing works smoothly across both screens.
  - [ ] `alx-link unpair <peer>` cleanly removes peer config and keys.
- [ ] **1-Hour Coding Session (Vostro 1015, 2 GB RAM):** Edit code in `nvim` + `tmux`, run Git commands, and browse docs in Firefox ESR with **5 open tabs** without system freeze or OOM crash.
